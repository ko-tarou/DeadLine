//
//  HomeViewModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//
import Foundation

class HomeViewModel: ObservableObject {
    @Published var items: [DeadlineItem] = []
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    func addItem(title: String, date: Date, memo: String) {
        let newItem = DeadlineItem(title: title, date: date, memo: memo)
        items.append(newItem)
    }
}

