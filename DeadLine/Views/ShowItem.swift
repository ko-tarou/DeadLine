//
//  ShowItem.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import SwiftUI

struct ShowItem: View {
    @Environment(\.dismiss) var dismiss
    
    var title: String
    var date: String
    var days: Int
    var memo: String
    
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
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
    }
}

#Preview {
    ShowItem(title: "title", date: "2025/3/3", days: 20, memo: "memo")
}
