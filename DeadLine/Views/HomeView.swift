//
//  MainScreenView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/19.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack{
            VStack{
                // Header
                
                ScrollView{
                    // top
                    TopView()
                    
                    // items
                    countItem()
                }
            }
        }
        .background(Color.gray)
    }
}

// top
struct TopView: View {
    var body: some View {
        HStack{
            // count
            Text("100")
                .font(.title)
            
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
    var body: some View {
        ZStack{
            HStack{
                VStack(alignment: .leading){
                    Text("Title")
                        .font(.title)
                    
                    Text("2020/22/22")
                        .font(.title3)
                }
                
                Spacer()
                
                HStack{
                    Text("100")
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
    
    countItem()
}

#Preview{
    HomeView()
}
