//
//  DeadLineModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import Foundation

struct DeadlineItem: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    
    var days: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: now, to: target)
        return components.day ?? 0
    }
    
    var memo: String
}
