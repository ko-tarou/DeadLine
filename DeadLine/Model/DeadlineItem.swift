//
//  DeadLineModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import Foundation
import SwiftData

// MARK: - DeadlineItem Model

@Model
final class DeadlineItem {
    var title: String
    var date: Date
    var memo: String
    var isPinned: Bool
    var createdDate: Date
    var updatedDate: Date
    
    // 計算プロパティ：残り日数
    var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTargetDate)
        return components.day ?? 0
    }
    
    // 計算プロパティ：期限切れかどうか
    var isOverdue: Bool {
        return daysRemaining < 0
    }
    
    // 計算プロパティ：今日が期限かどうか
    var isDueToday: Bool {
        return daysRemaining == 0
    }
    
    // 計算プロパティ：緊急度（7日以内）
    var isUrgent: Bool {
        return daysRemaining >= 0 && daysRemaining <= 7
    }
    
    // 計算プロパティ：期限まで1週間以内の警告
    var isWarning: Bool {
        return daysRemaining > 0 && daysRemaining <= 7
    }
    
    // 計算プロパティ：ステータステキスト
    var statusText: String {
        switch daysRemaining {
        case ..<0:
            return "\(abs(daysRemaining))日経過"
        case 0:
            return "今日まで"
        case 1:
            return "明日まで"
        default:
            return "\(daysRemaining)日後"
        }
    }
    
    init(title: String, date: Date, memo: String = "", isPinned: Bool = false) {
        self.title = title
        self.date = date
        self.memo = memo
        self.isPinned = isPinned
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

// MARK: - DeadlineItem Extensions

extension DeadlineItem {
    
    // 日付フォーマット関連
    func formattedDate(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    func shortFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    func longFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 相対日付
    func relativeDateString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // 優先度の計算
    func priorityScore() -> Int {
        var score = 0
        
        // ピン留めされている場合は最高優先度
        if isPinned {
            score += 1000
        }
        
        // 残り日数による優先度
        switch daysRemaining {
        case ..<0:
            score += 500 // 期限切れは高優先度
        case 0:
            score += 400 // 今日まで
        case 1...3:
            score += 300 // 3日以内
        case 4...7:
            score += 200 // 1週間以内
        default:
            score += max(0, 100 - daysRemaining) // 日数が少ないほど優先度高
        }
        
        return score
    }
    
    // バリデーション
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("タイトルが入力されていません")
        }
        
        if title.count > 100 {
            errors.append("タイトルは100文字以内で入力してください")
        }
        
        if memo.count > 1000 {
            errors.append("メモは1000文字以内で入力してください")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // 更新日時を現在時刻に設定
    func updateTimestamp() {
        updatedDate = Date()
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var errorMessage: String {
        errors.joined(separator: "\n")
    }
}

// MARK: - Sample Data

extension DeadlineItem {
    
    // サンプルデータ作成
    static func sampleData() -> [DeadlineItem] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            DeadlineItem(
                title: "プロジェクト提出",
                date: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
                memo: "最終レポートの提出期限です。必要な資料を全て揃えて提出してください。",
                isPinned: true
            ),
            DeadlineItem(
                title: "会議の準備",
                date: calendar.date(byAdding: .day, value: 3, to: today) ?? today,
                memo: "プレゼンテーション資料の作成と配布資料の印刷が必要です。"
            ),
            DeadlineItem(
                title: "定期健康診断",
                date: calendar.date(byAdding: .day, value: 14, to: today) ?? today,
                memo: "年に一度の健康診断です。前日は飲食制限があります。"
            ),
            DeadlineItem(
                title: "図書館の本返却",
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                memo: "期限切れです。延滞料金が発生している可能性があります。"
            ),
            DeadlineItem(
                title: "今日のタスク",
                date: today,
                memo: "今日中に完了させる必要があります。"
            )
        ]
    }
    
    // テスト用データ
    static func testData() -> DeadlineItem {
        return DeadlineItem(
            title: "テスト用タスク",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            memo: "これはテスト用のデータです。"
        )
    }
}

// MARK: - Query Helpers

extension DeadlineItem {
    
    // よく使用するクエリのヘルパー
    static var allItemsDescriptor: FetchDescriptor<DeadlineItem> {
        FetchDescriptor<DeadlineItem>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
    }
    
    static var pinnedItemsDescriptor: FetchDescriptor<DeadlineItem> {
        FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
        )
    }
    
    static var overdueItemsDescriptor: FetchDescriptor<DeadlineItem> {
        let today = Date()
        return FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { item in
                item.date < today
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
    }
    
    static var upcomingItemsDescriptor: FetchDescriptor<DeadlineItem> {
        let today = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        
        return FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { item in
                item.date >= today && item.date <= nextWeek
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
    }
}

// MARK: - Comparable Conformance

extension DeadlineItem: Comparable {
    static func < (lhs: DeadlineItem, rhs: DeadlineItem) -> Bool {
        // 優先度による比較
        let lhsPriority = lhs.priorityScore()
        let rhsPriority = rhs.priorityScore()
        
        if lhsPriority != rhsPriority {
            return lhsPriority > rhsPriority // 優先度が高い順
        }
        
        // 優先度が同じ場合は日付で比較
        return lhs.date < rhs.date
    }
}

// MARK: - Hashable Conformance (SwiftDataで自動生成されるが、明示的に定義)

extension DeadlineItem {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DeadlineItem, rhs: DeadlineItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Legacy Support (移行期間中のみ使用)

#if DEBUG
extension DeadlineItem {
    
    // Realm からの移行用ヘルパー（デバッグ時のみ）
    static func fromRealmData(title: String, date: Date, memo: String) -> DeadlineItem {
        return DeadlineItem(
            title: title,
            date: date,
            memo: memo,
            isPinned: false
        )
    }
    
    // デバッグ用の説明
    var debugDescription: String {
        return """
        DeadlineItem:
        - Title: \(title)
        - Date: \(date.formatted())
        - Days Remaining: \(daysRemaining)
        - Is Pinned: \(isPinned)
        - Status: \(statusText)
        - Created: \(createdDate.formatted())
        - Updated: \(updatedDate.formatted())
        """
    }
}
#endif
