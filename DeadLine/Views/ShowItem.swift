import SwiftUI
import RealmSwift

struct ShowItem: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAddItemModal = false
    @State private var showingDeleteAlert = false

    let id: ObjectId

    @State var title: String = ""
    @State var date: String = ""
    @State var days: Int = 0
    @State var memo: String = ""

    @State private var currentItem: DeadlineItem?

    var body: some View {
        NavigationView {
            ZStack{
                VStack{
                    Text(title)
                        .font(.title)
                                            
                    Text(date)
                    
                    VStack{
                        Text("\(days)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("day")
                    }
                    .padding()
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack(alignment: .leading){
                        Text("-memo-")
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                        Text(memo)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing])
                    
                    Spacer()
                }
                .padding([.leading, .trailing])
                .padding(.top, 30)
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
                            showingAddItemModal = true
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("削除")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            // 削除確認アラート
            .alert("削除の確認", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    viewModel.deleteItemById(id)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("このアイテムを削除してもよろしいですか？")
            }
        }
        .sheet(isPresented: $showingAddItemModal, onDismiss: {
            loadItem()
        }) {
            AddItemView(viewModel: viewModel, id: id)
        }
        .onAppear {
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
            } else {
                dismiss()
            }
        } catch {
            print("読み込みエラー: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ShowItem(viewModel: HomeViewModel(), id: ObjectId("68322467e2664f04688f9933"), title: "Title", date: "2025/4/4", days: 300, memo: "memomemo")
}
