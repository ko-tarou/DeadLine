//
//  AddItem.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI
import RealmSwift

enum InputMode: String, CaseIterable, Identifiable {
    case date = "日付で入力"
    case days = "残り日数で入力"
    
    var id: String { self.rawValue }
}

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel

    let id: ObjectId?

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var days: String = ""
    @State private var memo: String = ""
    @State private var inputMode: InputMode = .date
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    init(viewModel: HomeViewModel, id: ObjectId? = nil) {
            self.viewModel = viewModel
            self.id = id

            _title = State(initialValue: "")
            _date = State(initialValue: Date())
            _days = State(initialValue: "")
            _memo = State(initialValue: "")
            _inputMode = State(initialValue: .date)
        }

    var body: some View {
        NavigationView {
            Form {
                TextField("タイトル", text: $title)
                    .frame(height: 60)
                    .font(.title2)
                
                Section(header: Text("入力方法")) {
                    Picker("入力方法", selection: $inputMode) {
                        ForEach(InputMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section() {
                    if inputMode == .date {
                        DatePicker("日付", selection: $date, displayedComponents: .date)
                                } else {
                                    
                                    TextField("残り日数", text: $days)
                                        .keyboardType(.numberPad)
                                }
                }
                
                TextField("memo", text: $memo)
                    .frame(height: 150)
                
            }
            .onAppear {
                guard let id = id else { return }

                do {
                    let realm = try Realm()
                    if let item = realm.object(ofType: DeadlineItem.self, forPrimaryKey: id) {
                        title = item.title
                        date = item.date
                        memo = item.memo

                        let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: item.date).day ?? 0
                        if daysFromNow >= 0 {
                            inputMode = .days
                            days = String(daysFromNow)
                        } else {
                            inputMode = .date
                        }
                    }
                } catch {
                    print("データ取得失敗: \(error.localizedDescription)")
                }
            }

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    alertMessage = "タイトルを入力してください"
                                    showAlert = true
                                    return
                                }
                        
                        let adjustedDate: Date
                        if inputMode == .days {
                            guard let days = Int(days), days >= 0 else {
                                alertMessage = "残り日数は0以上の数字で入力してください"
                                showAlert = true
                                return
                            }
                            adjustedDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                        } else {
                            adjustedDate = date
                        }
                        
                        if let id = id {
                            // 更新処理
                            viewModel.updateItem(id: id, title: title, date: adjustedDate, memo: memo)
                        } else {
                            // 新規追加
                            viewModel.addItem(title: title, date: adjustedDate, memo: memo)
                        }
                        dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("入力エラー"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    AddItemView(viewModel: HomeViewModel())
}

#Preview {
    AddItemView(
        viewModel: HomeViewModel(),
        id:ObjectId("6832091a463778d96afa2ce9")
    )
}
