//
//  HomeViewModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//

import Foundation
import SwiftData
import WidgetKit
import SwiftUI

// MARK: - SwiftData対応のHomeViewModel (オプション)

@MainActor
class HomeViewModel: ObservableObject {
    
    // SwiftDataでは基本的にViewで直接@Queryを使用するため、
    // このViewModelは主にWidget連携とビジネスロジック用
    
    private var modelContext: ModelContext?
    
    // Widget用のデータ取得
    @Published var pinnedItemForWidget: DeadlineItem? = nil
    @Published var recentItemsForWidget: [DeadlineItem] = []
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Widget Support Methods
    
    /// Widget用のピン留めアイテムを取得
    func fetchPinnedItemForWidget() {
        guard let context = modelContext else { return }
        
        // FetchDescriptorを変数として作成
        var fetchDescriptor = FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1
        
        do {
            let pinnedItems = try context.fetch(fetchDescriptor)
            pinnedItemForWidget = pinnedItems.first
            
            // Widget を更新
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("ピン留めアイテムの取得エラー: \(error.localizedDescription)")
            pinnedItemForWidget = nil
        }
    }
    
    /// Widget用の最新アイテムを取得
    func fetchRecentItemsForWidget(limit: Int = 5) {
        guard let context = modelContext else { return }
        
        // FetchDescriptorを変数として作成
        var fetchDescriptor = FetchDescriptor<DeadlineItem>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = limit
        
        do {
            let items = try context.fetch(fetchDescriptor)
            recentItemsForWidget = items
            
            // Widget を更新
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("最新アイテムの取得エラー: \(error.localizedDescription)")
            recentItemsForWidget = []
        }
    }
    
    // MARK: - Utility Methods
    
    /// Date型を文字列に変換
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// 相対的な日付表現を取得
    func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// アイテムの緊急度を判定
    func urgencyLevel(for item: DeadlineItem) -> UrgencyLevel {
        let days = item.daysRemaining
        
        switch days {
        case ..<0:
            return .overdue
        case 0:
            return .today
        case 1...3:
            return .urgent
        case 4...7:
            return .warning
        default:
            return .normal
        }
    }
    
    // MARK: - Widget Data Refresh
    
    /// すべてのWidget関連データを更新
    func refreshAllWidgetData() {
        fetchPinnedItemForWidget()
        fetchRecentItemsForWidget()
    }
}

// MARK: - Urgency Level Enum

enum UrgencyLevel: String, CaseIterable {
    case overdue = "期限切れ"
    case today = "今日まで"
    case urgent = "緊急"
    case warning = "注意"
    case normal = "通常"
    
    var color: Color {
        switch self {
        case .overdue:
            return .red
        case .today:
            return .orange
        case .urgent:
            return .yellow
        case .warning:
            return .blue
        case .normal:
            return .primary
        }
    }
    
    var priority: Int {
        switch self {
        case .overdue: return 5
        case .today: return 4
        case .urgent: return 3
        case .warning: return 2
        case .normal: return 1
        }
    }
}

// MARK: - SwiftData Helper Extensions

extension HomeViewModel {
    
    /// ModelContextを設定
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshAllWidgetData()
    }
    
    /// 統計情報を取得
    func getStatistics() -> DeadlineStatistics? {
        guard let context = modelContext else { return nil }
        
        let allItemsDescriptor = FetchDescriptor<DeadlineItem>()
        
        do {
            let allItems = try context.fetch(allItemsDescriptor)
            
            let totalCount = allItems.count
            let overdueCount = allItems.filter { $0.isOverdue }.count
            let todayCount = allItems.filter { $0.isDueToday }.count
            let urgentCount = allItems.filter { $0.isUrgent }.count
            let pinnedCount = allItems.filter { $0.isPinned }.count
            
            return DeadlineStatistics(
                totalCount: totalCount,
                overdueCount: overdueCount,
                todayCount: todayCount,
                urgentCount: urgentCount,
                pinnedCount: pinnedCount
            )
        } catch {
            print("統計情報の取得エラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 期限切れのアイテムを取得
    func getOverdueItems() -> [DeadlineItem] {
        guard let context = modelContext else { return [] }
        
        let today = Date()
        let overdueDescriptor = FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { item in
                item.date < today
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(overdueDescriptor)
        } catch {
            print("期限切れアイテム取得エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 今後1週間のアイテムを取得
    func getUpcomingItems() -> [DeadlineItem] {
        guard let context = modelContext else { return [] }
        
        let today = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        
        let upcomingDescriptor = FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { item in
                item.date >= today && item.date <= nextWeek
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(upcomingDescriptor)
        } catch {
            print("今後のアイテム取得エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    /// アイテムの検索
    func searchItems(query: String) -> [DeadlineItem] {
        guard let context = modelContext, !query.isEmpty else { return [] }
        
        let searchDescriptor = FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { item in
                item.title.localizedStandardContains(query) ||
                item.memo.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            return try context.fetch(searchDescriptor)
        } catch {
            print("検索エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    /// アイテムの並び替え
    func getSortedItems(by sortOption: SortOption) -> [DeadlineItem] {
        guard let context = modelContext else { return [] }
        
        let sortDescriptor: SortDescriptor<DeadlineItem>
        
        switch sortOption {
        case .dateAscending:
            sortDescriptor = SortDescriptor(\.date, order: .forward)
        case .dateDescending:
            sortDescriptor = SortDescriptor(\.date, order: .reverse)
        case .titleAscending:
            sortDescriptor = SortDescriptor(\.title, order: .forward)
        case .titleDescending:
            sortDescriptor = SortDescriptor(\.title, order: .reverse)
        case .createdDate:
            sortDescriptor = SortDescriptor(\.createdDate, order: .reverse)
        }
        
        let sortedDescriptor = FetchDescriptor<DeadlineItem>(
            sortBy: [sortDescriptor]
        )
        
        do {
            return try context.fetch(sortedDescriptor)
        } catch {
            print("並び替えエラー: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case dateAscending = "期限日（昇順）"
    case dateDescending = "期限日（降順）"
    case titleAscending = "タイトル（昇順）"
    case titleDescending = "タイトル（降順）"
    case createdDate = "作成日"
}

// MARK: - Statistics Model

struct DeadlineStatistics {
    let totalCount: Int
    let overdueCount: Int
    let todayCount: Int
    let urgentCount: Int
    let pinnedCount: Int
    
    var completionRate: Double {
        guard totalCount > 0 else { return 0.0 }
        let completedCount = totalCount - overdueCount
        return Double(completedCount) / Double(totalCount)
    }
    
    var urgencyRate: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(urgentCount) / Double(totalCount)
    }
}

// MARK: - Widget Data Provider (シングルトン)

@MainActor
class WidgetDataProvider: ObservableObject {
    static let shared = WidgetDataProvider()
    
    private var modelContainer: ModelContainer?
    
    private init() {
        setupModelContainer()
    }
    
    private func setupModelContainer() {
        modelContainer = SwiftDataConfig.createSharedModelContainer(DeadlineItem.self)
    }
    
    /// Widget用のピン留めアイテムを取得
    func getPinnedItemForWidget() -> DeadlineItem? {
        guard let container = modelContainer else { return nil }
        
        let context = container.mainContext
        
        var fetchDescriptor = FetchDescriptor<DeadlineItem>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1
        
        do {
            let pinnedItems = try context.fetch(fetchDescriptor)
            return pinnedItems.first
        } catch {
            print("Widget用ピン留めアイテム取得エラー: \(error)")
            return nil
        }
    }
    
    /// Widget用の最新アイテムリストを取得
    func getRecentItemsForWidget(limit: Int = 3) -> [DeadlineItem] {
        guard let container = modelContainer else { return [] }
        
        let context = container.mainContext
        
        var fetchDescriptor = FetchDescriptor<DeadlineItem>(
            sortBy: [SortDescriptor(\.daysRemaining, order: .forward)]
        )
        fetchDescriptor.fetchLimit = limit
        
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Widget用最新アイテム取得エラー: \(error)")
            return []
        }
    }
    
    /// Widget用の統計情報を取得
    func getWidgetStatistics() -> DeadlineStatistics? {
        guard let container = modelContainer else { return nil }
        
        let context = container.mainContext
        let allItemsDescriptor = FetchDescriptor<DeadlineItem>()
        
        do {
            let allItems = try context.fetch(allItemsDescriptor)
            
            let totalCount = allItems.count
            let overdueCount = allItems.filter { $0.isOverdue }.count
            let todayCount = allItems.filter { $0.isDueToday }.count
            let urgentCount = allItems.filter { $0.isUrgent }.count
            let pinnedCount = allItems.filter { $0.isPinned }.count
            
            return DeadlineStatistics(
                totalCount: totalCount,
                overdueCount: overdueCount,
                todayCount: todayCount,
                urgentCount: urgentCount,
                pinnedCount: pinnedCount
            )
        } catch {
            print("Widget統計情報取得エラー: \(error)")
            return nil
        }
    }
}
