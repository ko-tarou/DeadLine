//
//  ShowItem.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI
import RealmSwift

struct ShowItem: View {
    @ObservedObject var viewModel = HomeViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingAddItemModal = false
    
    let id: ObjectId

    @State var title: String
    @State var date: String
    @State var days: Int
    @State var memo: String
    
    var body: some View {
        NavigationView {
            Form {
                Text(title)
                
                Text(date)
                
                Text("\(days)")
                Text("day")
                
                Text(memo)
            
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("編集") {
                            print("編集 tapped")
                            showingAddItemModal = true
                        }
                                            
                        Button(role: .destructive) {
                            print("削除 tapped")
                            dismiss()
                        } label: {
                            Text("削除")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .sheet(isPresented: $showingAddItemModal, onDismiss: {
                        loadItem()
                    }){
                        AddItemView(viewModel: viewModel, id: id)
                    }
                }
            }
        }
        .onAppear{
            loadItem()
        }
    }
    
    func loadItem() {
        do {
            let realm = try Realm()
            if let item = realm.object(ofType: DeadlineItem.self, forPrimaryKey: id) {
                title = item.title
                memo = item.memo
                date = item.date.formatted()
                days = Calendar.current.dateComponents([.day], from: Date(), to: item.date).day ?? 0
            }
        } catch {
            print("読み込みエラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ShowItem(id:ObjectId("6831e2010445556254a6bd18"), title: "title", date: "2025/3/3", days: 20, memo: "memo")
}
