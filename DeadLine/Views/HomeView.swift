//
//  MainScreenView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/19.
//


import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @State private var showingAddItemModal = false
    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    // Header
                    
                    // top
                    TopView()
                    
                    
                    // items
                    List{
                        ForEach(viewModel.items){ item in
                            var title = item.title
                            var date = item.date.formatted()
                            var days = item.days
                            
                            NavigationLink(destination: Text("🍊")){
                                countItem(title: title, date: date, days: days)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let item = viewModel.items[index]
                                viewModel.deleteItem(item)
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
    var body: some View {
        HStack{
            // count
            Text("100")
                .font(.title2)
            
            VStack(alignment: .leading){
                // title
                Text("title")
                    .font(.title2)
                
                // day
                Text("2020/02/22")
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
