//
//  DeadLineModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import Foundation
import RealmSwift

class DeadlineItem: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String = ""
    @Persisted var date: Date = Date()
    @Persisted var memo: String = ""

    // 日数計算（保存はしない）
    var days: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: now, to: target)
        return components.day ?? 0
    }
}

class PinnedItem: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var pinnedId: ObjectId
}

