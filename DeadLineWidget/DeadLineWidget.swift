//
//  DeadLineWidget.swift
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget専用データモデル
@Model
final class WidgetDeadlineItem {
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
    
    init(title: String, date: Date, memo: String = "", isPinned: Bool = false) {
        self.title = title
        self.date = date
        self.memo = memo
        self.isPinned = isPinned
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

// MARK: - Widget設定
struct WidgetConfig {
    static let appGroupIdentifier = "group.deadline.shared"
    static let databaseFileName = "DeadlineDatabase.sqlite"
    
    static var sharedDatabaseURL: URL {
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            // フォールバック
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsPath.appendingPathComponent(databaseFileName)
        }
        
        return appGroupURL.appendingPathComponent(databaseFileName)
    }
    
    static func createModelContainer() -> ModelContainer? {
        do {
            // Widget専用のモデルコンテナを作成
            let container = try ModelContainer(
                for: WidgetDeadlineItem.self,
                configurations: ModelConfiguration(
                    url: sharedDatabaseURL,
                    cloudKitDatabase: .none
                )
            )
            return container
        } catch {
            print("Widget ModelContainer 作成エラー: \(error)")
            
            // フォールバック: インメモリコンテナ
            do {
                return try ModelContainer(
                    for: WidgetDeadlineItem.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                print("フォールバック ModelContainer 作成エラー: \(error)")
                return nil
            }
        }
    }
}

// MARK: - データ同期サービス
struct WidgetDataSync {
    
    // メインアプリからWidgetにデータを同期
    static func syncFromMainApp() {
        // UserDefaults を使用してデータを同期
        let userDefaults = UserDefaults(suiteName: WidgetConfig.appGroupIdentifier)
        
        guard let data = userDefaults?.data(forKey: "widgetData"),
              let items = try? JSONDecoder().decode([WidgetItemData].self, from: data) else {
            print("Widget用データが見つかりません")
            return
        }
        
        guard let container = WidgetConfig.createModelContainer() else {
            print("ModelContainer の作成に失敗")
            return
        }
        
        // Main Actorを使用しない同期処理
        Task {
            await performDataSync(container: container, items: items)
        }
    }
    
    @MainActor
    private static func performDataSync(container: ModelContainer, items: [WidgetItemData]) {
        let context = container.mainContext
        
        do {
            // 既存データを削除
            try context.delete(model: WidgetDeadlineItem.self)
            
            // 新しいデータを挿入
            for itemData in items {
                let widgetItem = WidgetDeadlineItem(
                    title: itemData.title,
                    date: itemData.date,
                    memo: itemData.memo,
                    isPinned: itemData.isPinned
                )
                context.insert(widgetItem)
            }
            
            try context.save()
            print("Widget データ同期完了: \(items.count) 件")
            
        } catch {
            print("Widget データ同期エラー: \(error)")
        }
    }
    
    static func fetchWidgetData() -> WidgetDeadlineItem? {
        // まずUserDefaultsから最新データを同期
        syncFromMainApp()
        
        guard let container = WidgetConfig.createModelContainer() else {
            return nil
        }
        
        // 非同期でデータを取得
        return fetchDataSync(container: container)
    }
    
    private static func fetchDataSync(container: ModelContainer) -> WidgetDeadlineItem? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: WidgetDeadlineItem?
        
        Task {
            result = await performDataFetch(container: container)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    @MainActor
    private static func performDataFetch(container: ModelContainer) -> WidgetDeadlineItem? {
        let context = container.mainContext
        let currentDate = Date() // Predicate外で現在日時を取得
        
        do {
            // ピン留めされたアイテムを優先取得
            var pinnedDescriptor = FetchDescriptor<WidgetDeadlineItem>(
                predicate: #Predicate<WidgetDeadlineItem> { item in
                    item.isPinned == true && item.date >= currentDate
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            pinnedDescriptor.fetchLimit = 1
            
            let pinnedItems = try context.fetch(pinnedDescriptor)
            if let pinnedItem = pinnedItems.first {
                return pinnedItem
            }
            
            // ピン留めがない場合、最も近い期限のアイテムを取得
            var upcomingDescriptor = FetchDescriptor<WidgetDeadlineItem>(
                predicate: #Predicate<WidgetDeadlineItem> { item in
                    item.date >= currentDate
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            upcomingDescriptor.fetchLimit = 1
            
            let upcomingItems = try context.fetch(upcomingDescriptor)
            return upcomingItems.first
            
        } catch {
            print("Widget データ取得エラー: \(error)")
            return nil
        }
    }
}

// MARK: - データ転送用構造体
struct WidgetItemData: Codable {
    let title: String
    let date: Date
    let memo: String
    let isPinned: Bool
}

// ───── Provider ─────
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, daysLeft: nil, itemTitle: nil, isPinned: false)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<SimpleEntry>) -> Void) {

        let now = Date()
        let entries: [SimpleEntry] = (0..<3).map { offset in
            let entryDate = Calendar.current.date(byAdding: .hour, value: offset * 2, to: now) ?? now
            return makeEntry(for: entryDate)
        }
        
        // 次の更新タイミングを設定（2時間後）
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }

    private func makeEntry(for date: Date) -> SimpleEntry {
        if let widgetItem = WidgetDataSync.fetchWidgetData() {
            return SimpleEntry(
                date: date,
                daysLeft: widgetItem.daysRemaining,
                itemTitle: widgetItem.title,
                isPinned: widgetItem.isPinned
            )
        }
        
        return SimpleEntry(date: date, daysLeft: nil, itemTitle: nil, isPinned: false)
    }
}

// ───── Entry ─────
struct SimpleEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int?
    let itemTitle: String?
    let isPinned: Bool
}

// ───── View ─────
struct DeadLineWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            // 背景
            ContainerRelativeShape()
                .fill(.tertiary)
            
            VStack(spacing: spacing(for: family)) {
                if let title = entry.itemTitle,
                   let days = entry.daysLeft {
                    
                    // ピン留めインジケーター
                    if entry.isPinned && family != .systemSmall {
                        HStack {
                            Spacer()
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // タイトル
                    Text(title)
                        .font(titleFont(for: family))
                        .lineLimit(titleLineLimit(for: family))
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 残り日数
                    VStack(spacing: 2) {
                        Text("\(abs(days))")
                            .font(daysFont(for: family))
                            .fontWeight(.bold)
                            .foregroundColor(daysColor(for: days))
                        
                        Text(days < 0 ? "日経過" : "日後")
                            .font(dayLabelFont(for: family))
                            .foregroundColor(.secondary)
                    }
                    
                    // ステータス
                    if family != .systemSmall {
                        statusText(for: days)
                    }
                    
                } else {
                    // データなし
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: iconSize(for: family)))
                            .foregroundColor(.gray)
                        
                        Text("タスクなし")
                            .font(noDataFont(for: family))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(paddingSize(for: family))
        }
    }
    
    @ViewBuilder
    private func statusText(for days: Int) -> some View {
        Group {
            switch days {
            case ..<0:
                Text("期限切れ")
                    .foregroundColor(.red)
            case 0:
                Text("今日まで")
                    .foregroundColor(.orange)
            case 1...3:
                Text("急ぎ")
                    .foregroundColor(.yellow)
            default:
                EmptyView()
            }
        }
        .font(.caption2)
        .fontWeight(.semibold)
    }

    // MARK: - Style Helpers
    
    private func titleFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 11, weight: .medium)
        case .systemMedium:
            return .system(size: 14, weight: .medium)
        case .systemLarge:
            return .system(size: 18, weight: .medium)
        case .systemExtraLarge:
            return .system(size: 22, weight: .medium)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return .system(size: 10, weight: .medium)
        @unknown default:
            return .body
        }
    }
    
    private func daysFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 24, weight: .bold, design: .rounded)
        case .systemMedium:
            return .system(size: 36, weight: .bold, design: .rounded)
        case .systemLarge:
            return .system(size: 48, weight: .bold, design: .rounded)
        case .systemExtraLarge:
            return .system(size: 60, weight: .bold, design: .rounded)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return .system(size: 16, weight: .bold, design: .rounded)
        @unknown default:
            return .title
        }
    }
    
    private func dayLabelFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 9, weight: .medium)
        case .systemMedium:
            return .system(size: 12, weight: .medium)
        case .systemLarge:
            return .system(size: 14, weight: .medium)
        case .systemExtraLarge:
            return .system(size: 16, weight: .medium)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return .system(size: 8, weight: .medium)
        @unknown default:
            return .caption
        }
    }
    
    private func noDataFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:
            return .system(size: 10)
        case .systemMedium:
            return .system(size: 12)
        case .systemLarge:
            return .system(size: 14)
        case .systemExtraLarge:
            return .system(size: 16)
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return .system(size: 8)
        @unknown default:
            return .caption
        }
    }
    
    private func titleLineLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 2
        case .systemLarge:
            return 3
        case .systemExtraLarge:
            return 4
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 1
        @unknown default:
            return 1
        }
    }
    
    private func iconSize(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 16
        case .systemMedium:
            return 24
        case .systemLarge:
            return 32
        case .systemExtraLarge:
            return 40
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 12
        @unknown default:
            return 20
        }
    }
    
    private func paddingSize(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 8
        case .systemMedium:
            return 12
        case .systemLarge:
            return 16
        case .systemExtraLarge:
            return 20
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 4
        @unknown default:
            return 8
        }
    }
    
    private func spacing(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            return 2
        case .systemMedium:
            return 4
        case .systemLarge:
            return 6
        case .systemExtraLarge:
            return 8
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return 1
        @unknown default:
            return 2
        }
    }
    
    private func daysColor(for days: Int) -> Color {
        switch days {
        case ..<0:
            return .red
        case 0:
            return .orange
        case 1...3:
            return .yellow
        case 4...7:
            return .blue
        default:
            return .primary
        }
    }
}

// ───── Widget ─────
struct DeadLineWidget: Widget {
    let kind = "DeadLineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DeadLineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DeadLine")
        .description("次の期限までの日数を表示")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ───── Preview ─────
#Preview(as: .systemSmall) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now, daysLeft: 3, itemTitle: "プロジェクト", isPinned: true)
    SimpleEntry(date: .now, daysLeft: nil, itemTitle: nil, isPinned: false)
}
