//
//  AddItemView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI
import SwiftData

enum InputMode: String, CaseIterable, Identifiable {
    case date = "日付で入力"
    case days = "残り日数で入力"
    
    var id: String { self.rawValue }
}

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let editingItem: DeadlineItem?
    
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var days: String = ""
    @State private var memo: String = ""
    @State private var inputMode: InputMode = .date
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @FocusState private var isTitleFieldFocused: Bool
    @FocusState private var isDaysFieldFocused: Bool
    
    // 編集モードかどうかを判定
    private var isEditMode: Bool {
        editingItem != nil
    }
    
    // 新規作成用のイニシャライザ
    init() {
        self.editingItem = nil
    }
    
    // 編集用のイニシャライザ
    init(editingItem: DeadlineItem) {
        self.editingItem = editingItem
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // タイトル入力セクション
                VStack(alignment: .leading, spacing: 2) {
                    TextField("タイトルを入力", text: $title)
                        .frame(maxWidth: .infinity)
                        .font(.title2)
                        .focused($isTitleFieldFocused)
                    
                    Rectangle()
                        .frame(height: 1.5)
                        .foregroundColor(isTitleFieldFocused ? .blue : .gray.opacity(0.5))
                        .padding(.top, 2)
                }
                .listRowSeparator(.hidden)
                
                // 入力方法選択セクション
                VStack(spacing: 16) {
                    Section {
                        Text("入力方法")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Picker("入力方法", selection: $inputMode) {
                            ForEach(InputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // 日付/日数入力セクション
                    Section {
                        if inputMode == .date {
                            DatePicker("日付", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        } else {
                            HStack {
                                Text("残り日数")
                                    .font(.body)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    TextField("0", text: $days)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                        .focused($isDaysFieldFocused)
                                    
                                    Rectangle()
                                        .frame(width: 70, height: 1.5)
                                        .foregroundColor(isDaysFieldFocused ? .blue : Color.gray.opacity(0.5))
                                }
                                
                                Text("日後")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .frame(minHeight: 50)
                        }
                    }
                }
                .padding(.vertical)
                
                // メモ入力セクション
                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $memo)
                        .frame(height: 150)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? "編集" : "新規作成")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadItemForEditing()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("入力エラー", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadItemForEditing() {
        guard let item = editingItem else { return }
        
        title = item.title
        date = item.date
        memo = item.memo
        
        // 現在日からの日数を計算
        let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: item.date).day ?? 0
        
        if daysFromNow >= 0 {
            inputMode = .days
            days = String(daysFromNow)
        } else {
            inputMode = .date
        }
    }
    
    private func saveItem() {
        // バリデーション
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "タイトルを入力してください"
            showAlert = true
            return
        }
        
        // 日付の計算
        let finalDate: Date
        if inputMode == .days {
            guard let daysInt = Int(days), daysInt >= 0 else {
                alertMessage = "残り日数は0以上の数字で入力してください"
                showAlert = true
                return
            }
            finalDate = Calendar.current.date(byAdding: .day, value: daysInt, to: Date()) ?? Date()
        } else {
            finalDate = date
        }
        
        if let item = editingItem {
            // 既存アイテムの更新
            updateExistingItem(item, title: title, date: finalDate, memo: memo)
        } else {
            // 新規アイテムの作成
            createNewItem(title: title, date: finalDate, memo: memo)
        }
        
        dismiss()
    }
    
    private func createNewItem(title: String, date: Date, memo: String) {
        let newItem = DeadlineItem(
            title: title,
            date: date,
            memo: memo
        )
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
        } catch {
            print("アイテム作成エラー: \(error.localizedDescription)")
            alertMessage = "保存に失敗しました"
            showAlert = true
        }
    }
    
    private func updateExistingItem(_ item: DeadlineItem, title: String, date: Date, memo: String) {
        item.title = title
        item.date = date
        item.memo = memo
        item.updatedDate = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("アイテム更新エラー: \(error.localizedDescription)")
            alertMessage = "更新に失敗しました"
            showAlert = true
        }
    }
}

// MARK: - Previews

#Preview("新規作成") {
    AddItemView()
        .modelContainer(for: DeadlineItem.self, inMemory: true)
}

#Preview("編集モード") {
    let container = try! ModelContainer(for: DeadlineItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let sampleItem = DeadlineItem(
        title: "サンプルタスク",
        date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        memo: "これはサンプルのメモです"
    )
    container.mainContext.insert(sampleItem)
    
    return AddItemView(editingItem: sampleItem)
        .modelContainer(container)
}
