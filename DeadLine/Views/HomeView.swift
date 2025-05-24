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

func printRealmPath() {
    if let realmURL = Realm.Configuration.defaultConfiguration.fileURL {
        print("Realm is located at:", realmURL.path)
    } else {
        print("Could not determine Realm file URL.")
    }
}

struct HomeView: View {
    @ObservedObject var viewModel = HomeViewModel()
    @State private var showingAddItemModal = false
    @State private var selectedId: ObjectId? = nil
    @State private var isShowingDetailSheet = false

    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    Button("show realm path") {
                        printRealmPath()
                    }
                    
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
                            countItem(
                                title: item.title,
                                date: item.date.formatted(),
                                days: item.days
                            )
                            .onTapGesture {
                                selectedId = item.id
                                isShowingDetailSheet = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            viewModel.pinItem(item)
                                        } label: {
                                            Label("ピン留め", systemImage: "pin.fill")
                                        }
                                        .tint(.yellow)
                                }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let item = viewModel.items[index]
                                do {
                                    viewModel.deleteItemById(item.id)
                                } catch {
                                    print("delete error")
                                }
                            }
                        }
                    } // Listここまで
                } // VStack
            }// ZStack
            .background(Color.gray)
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
            // count
            Text("\(days)")
                .font(.title2)
            
            VStack(alignment: .leading){
                // title
                Text(title)
                    .font(.title2)
                
                // day
                Text(date)
            }
            
        }
    }
}

// item
struct countItem: View {
    var title: String
    var date: String
    var days: Int
    
    var body: some View {
        ZStack{
            HStack{
                VStack(alignment: .leading){
                    Text(title)
                        .font(.title)
                    
                    Text(date)
                        .font(.title3)
                }
                
                Spacer()
                
                HStack{
                    Text("\(days)")
                        .font(.title)
                    
                    Text("day")
                        .font(.title3)
                }
            }
            .padding()
        }
        .frame(width: 350, height: 100)
        .background(Color.white)
        .cornerRadius(16)
    }
    
}


#Preview {
//    HomeView()
    
    countItem(title:"title", date:"2025/07/29", days:100)
}

#Preview{
    HomeView()
}
