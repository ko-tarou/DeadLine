//
//  AddItem.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI

enum InputMode: String, CaseIterable, Identifiable {
    case date = "日付で入力"
    case days = "残り日数で入力"
    
    var id: String { self.rawValue }
}

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var days: String = ""
    @State private var memo: String = ""
    @State private var inputMode: InputMode = .date
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    alertMessage = "タイトルを入力してください"
                                    showAlert = true
                                    return
                                }
                        
                        if inputMode == .days {
                            guard let days = Int(days), days >= 0 else {
                                alertMessage = "残り日数は0以上の数字で入力してください"
                                showAlert = true
                                return
                            }
                            let adjustedDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                            viewModel.addItem(title: title, date: adjustedDate, memo: memo)
                        } else {
                            viewModel.addItem(title: title, date: date, memo: memo)
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
