//
//  MainScreenView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/19.
//


import SwiftUI
import RealmSwift


extension ObjectId: Identifiable {
    public var id: ObjectId { self }
}

//func printRealmPath() {
//    if let realmURL = Realm.Configuration.defaultConfiguration.fileURL {
//        print("Realm is located at:", realmURL.path)
//    } else {
//        print("Could not determine Realm file URL.")
//    }
//}

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()
    @State private var showingAddItemModal = false
    @State private var selectedId: ObjectId? = nil
    @State private var isShowingDetailSheet = false

    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    // Header
                    
                    // top
                    if let pinnedItem = viewModel.pinnedItem {
                        TopView(days: pinnedItem.days, title: pinnedItem.title, date: viewModel.formattedDate(pinnedItem.date))
                    } else {
                        Text("not pin")
                    }
                    
                    
                    
                    // items
                    List{
                        ForEach(viewModel.items){ item in
                            let isCurrentItemPinned = (viewModel.pinnedItem?.id == item.id)
                            
                            ZStack(alignment: .topLeading){
                                countItem(
                                    title: item.title,
                                    date: item.date.formatted(),
                                    days: item.days,
                                    isPin: isCurrentItemPinned
                                )
                                
//                                if viewModel.pinnedItem?.id == item.id {
//                                    // ピンマーク（右上に表示）
//                                    Image(systemName: "pin.circle.fill")
//                                        .foregroundColor(.blue)
////                                        .padding()
//                                }
                            }
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            // ここまでアイテムの設定
                            .onTapGesture {
                                selectedId = item.id
                                isShowingDetailSheet = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            viewModel.pinItem(item)
                                        } label: {
                                            Image(systemName: viewModel.pinnedItem?.id == item.id ? "pin.slash.fill" : "pin.fill")
                                        }
                                        .tint(.yellow)
                                }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let item = viewModel.items[index]
                                viewModel.deleteItemById(item.id)

                            }
                        }
                    } // Listここまで
                    .listStyle(.plain)
                    .background(Color.clear)
                } // VStack
                .padding()
            }// ZStack
            .background(Color(.systemGray6))
            .safeAreaInset(edge: .bottom, alignment: .trailing ){
                addButtonView{
                    showingAddItemModal = true
                } //プラスボタン
            }
        }// NavigationView
        .onAppear{
            viewModel.fetchItems()
        }
        .sheet(isPresented: $showingAddItemModal){
            AddItemView(viewModel: viewModel)
        }
        .sheet(item: $selectedId) { id in
            ShowItem(viewModel: viewModel, id: id)
        }

    }
}


// add button
struct addButtonView: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: {onTap()}){
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
        }
    }
}


// top
struct TopView: View {
    var days: Int
    var title: String
    var date: String
    
    var body: some View {
        HStack{
            // 左側
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 130)
                    .overlay{
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    }
                
                // 残り日数
                Text("\(days)")
                    .font(.title)
            }
            .padding()
            
            VStack(alignment: .leading){
                // title
                Text(title)
                    .font(.title2)
                
                // day
                Text(date)
            }
            
            Spacer()
            
        }
    }
}

// item
struct countItem: View {
    var title: String
    var date: String
    var days: Int
    var isPin: Bool
    
    var body: some View {
        ZStack{
            HStack{
                if isPin {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 23))
                }
                
                VStack(alignment: .leading){
                    Text(title)
                        .font(.title2)
                    
                    Text(date)
                }
                
                Spacer()
                
                HStack{
                    Text("\(days)")
                        .font(.title)
                    
                    Text("day")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
}


#Preview {
//    HomeView()
    
//    countItem(title:"title", date:"2025/07/29", days:100)
    
    TopView(days: 10, title: "pinnedItem.title", date: "2025/3/3")
}

#Preview{
    HomeView()
}
