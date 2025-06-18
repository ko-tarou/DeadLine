//
//  ShowItemView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI
import SwiftData

struct ShowItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let item: DeadlineItem
    
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    
    // 計算プロパティで動的に値を取得
    private var formattedDate: String {
        item.date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var daysRemaining: Int {
        item.daysRemaining
    }
    
    private var dayStatusColor: Color {
        switch daysRemaining {
        case ..<0:
            return .red
        case 0...7:
            return .orange
        default:
            return .primary
        }
    }
    
    private var dayStatusText: String {
        if daysRemaining < 0 {
            return "期限切れ"
        } else if daysRemaining == 0 {
            return "今日まで"
        } else {
            return "\(daysRemaining)日後"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー部分
                    VStack(spacing: 12) {
                        Text(item.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(formattedDate)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 残り日数表示
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(dayStatusColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Circle()
                                        .stroke(dayStatusColor, lineWidth: 3)
                                }
                            
                            VStack(spacing: 4) {
                                Text("\(abs(daysRemaining))")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(dayStatusColor)
                                
                                Text(daysRemaining < 0 ? "日経過" : "日")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(dayStatusText)
                            .font(.headline)
                            .foregroundColor(dayStatusColor)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical)
                    
                    // 区切り線
                    Divider()
                        .padding(.horizontal)
                    
                    // メモ部分
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("メモ")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Group {
                            if item.memo.isEmpty {
                                Text("メモはありません")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(item.memo)
                                    .font(.body)
                                    .lineLimit(nil)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 作成日時・更新日時
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("作成日時:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(item.createdDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        if item.updatedDate.timeIntervalSince(item.createdDate) > 60 {
                            HStack {
                                Text("更新日時:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(item.updatedDate.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditModal = true
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditModal) {
            AddItemView(editingItem: item)
        }
        .alert("削除の確認", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteItem()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("「\(item.title)」を削除してもよろしいですか？この操作は取り消せません。")
        }
    }
    
    // MARK: - Private Methods
    
    private func deleteItem() {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("削除エラー: \(error.localizedDescription)")
            // エラーハンドリングをここに追加可能
        }
    }
}

// MARK: - Previews

#Preview("通常のアイテム") {
    let container = try! ModelContainer(
        for: DeadlineItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let sampleItem = DeadlineItem(
        title: "プロジェクト完了",
        date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        memo: "これは重要なプロジェクトです。期限までに必ず完了させる必要があります。"
    )
    container.mainContext.insert(sampleItem)
    
    return ShowItemView(item: sampleItem)
        .modelContainer(container)
}

#Preview("期限切れアイテム") {
    let container = try! ModelContainer(
        for: DeadlineItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let expiredItem = DeadlineItem(
        title: "期限切れタスク",
        date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        memo: "このタスクは期限が過ぎています。"
    )
    container.mainContext.insert(expiredItem)
    
    return ShowItemView(item: expiredItem)
        .modelContainer(container)
}

#Preview("メモなしアイテム") {
    let container = try! ModelContainer(
        for: DeadlineItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let noMemoItem = DeadlineItem(
        title: "シンプルなタスク",
        date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        memo: ""
    )
    container.mainContext.insert(noMemoItem)
    
    return ShowItemView(item: noMemoItem)
        .modelContainer(container)
}
