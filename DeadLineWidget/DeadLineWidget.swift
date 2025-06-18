//
//  DeadLineWidget.swift
//

import WidgetKit
import SwiftUI

// MARK: - データ転送用構造体（ウィジェット用）
struct WidgetItemData: Codable {
    let title: String
    let date: Date
    let memo: String
    let isPinned: Bool
    
    // 残り日数を計算
    var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTargetDate)
        return components.day ?? 0
    }
}

// MARK: - Widget データ管理 (Step 2: デバッグ強化版)
struct WidgetDataManager {
    static let appGroupIdentifier = "group.deadline.app.shared"
    static let dataKey = "widgetData"
    
    // UserDefaults からデータを取得 (Step 2: デバッグ強化版)
    static func loadWidgetData() -> [WidgetItemData] {
        print("📱 Widget: データ読み込み開始")
        print("📱 Widget: App Group ID: \(appGroupIdentifier)")
        print("📱 Widget: Data Key: \(dataKey)")
        
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Widget: UserDefaults アクセス失敗")
            return []
        }
        
        // 強制リロード
        userDefaults.synchronize()
        print("✅ Widget: UserDefaults 取得成功 & 同期完了")
        
        // すべてのキーを確認
        let allKeys = userDefaults.dictionaryRepresentation().keys
        print("📱 Widget: 利用可能なキー: \(Array(allKeys))")
        
        // 特定のキーの詳細確認
        if let testData = userDefaults.object(forKey: "test") {
            print("📱 Widget: testキーの値: \(testData)")
            print("📱 Widget: testキーの型: \(type(of: testData))")
        }
        
        // appGroupTest キーの確認
        if let appGroupTestData = userDefaults.object(forKey: "appGroupTest") {
            print("📱 Widget: appGroupTestキーの値: \(appGroupTestData)")
        }
        
        // widgetData キーの詳細確認
        if let widgetDataObject = userDefaults.object(forKey: dataKey) {
            print("📱 Widget: widgetDataキー発見!")
            print("📱 Widget: widgetDataキーの型: \(type(of: widgetDataObject))")
            
            if let data = widgetDataObject as? Data {
                print("📱 Widget: widgetDataサイズ: \(data.count) bytes")
                
                // 16進ダンプで内容確認
                let hexString = data.map { String(format: "%02x", $0) }.joined()
                print("📱 Widget: widgetData内容(hex): \(String(hexString.prefix(100)))...")
                
                // 文字列として確認
                if let stringData = String(data: data, encoding: .utf8) {
                    print("📱 Widget: widgetData内容(string): \(String(stringData.prefix(200)))...")
                }
            } else {
                print("📱 Widget: widgetDataキーはDataタイプではありません")
            }
        } else {
            print("❌ Widget: widgetDataキーが見つかりません")
            
            // 類似キーの検索
            let similarKeys = allKeys.filter { $0.lowercased().contains("widget") || $0.lowercased().contains("data") }
            if !similarKeys.isEmpty {
                print("📱 Widget: 類似キー: \(similarKeys)")
            }
            
            // すべてのカスタムキー（システムキー以外）を表示
            let systemKeys = ["AppleLanguages", "AppleLocale", "AppleKeyboards", "AppleKeyboardsExpanded", "ApplePasscodeKeyboards", "NSLanguages", "NSInterfaceStyle", "AKLastIDMSEnvironment", "AKLastLocale", "PKLogNotificationServiceResponsesKey", "AppleLanguagesSchemaVersion", "AddingEmojiKeybordHandled"]
            let customKeys = allKeys.filter { !systemKeys.contains($0) }
            print("📱 Widget: カスタムキー: \(Array(customKeys))")
        }
        
        guard let data = userDefaults.data(forKey: dataKey) else {
            print("❌ Widget: データ取得失敗")
            return []
        }
        
        print("✅ Widget: データ取得成功 - サイズ: \(data.count) bytes")
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([WidgetItemData].self, from: data)
            print("✅ Widget: \(items.count) 件のデータをデコードしました")
            
            // デバッグ情報
            for (index, item) in items.enumerated() {
                print("📱 Widget[\(index)]: \(item.title) - ピン: \(item.isPinned) - 残り: \(item.daysRemaining)日")
            }
            
            return items
        } catch {
            print("❌ Widget: データデコードエラー: \(error)")
            return []
        }
    }
    
    // ピン留めアイテムを取得
    static func getPinnedItem() -> WidgetItemData? {
        let items = loadWidgetData()
        
        print("🔍 Widget: ピン留めアイテム検索開始 - 総数: \(items.count)")
        
        let pinnedItems = items.filter { $0.isPinned }
        print("🔍 Widget: ピン留めアイテム数: \(pinnedItems.count)")
        
        let pinnedItem = pinnedItems.first
        
        if let pinned = pinnedItem {
            print("📌 Widget: ピン留めアイテム見つかりました: \(pinned.title) (\(pinned.daysRemaining)日)")
            return pinned
        } else {
            print("📌 Widget: ピン留めアイテムが見つかりません")
            return nil
        }
    }
    
    // 最も近い期限のアイテムを取得
    static func getUpcomingItem() -> WidgetItemData? {
        let items = loadWidgetData()
        let today = Date()
        let futureItems = items.filter { $0.date >= today }
        let sortedItems = futureItems.sorted { $0.date < $1.date }
        
        let upcomingItem = sortedItems.first
        
        if let upcoming = upcomingItem {
            print("📅 Widget: 次の期限アイテム: \(upcoming.title) (\(upcoming.daysRemaining)日)")
            return upcoming
        } else {
            print("📅 Widget: 今後の期限アイテムが見つかりません")
            return nil
        }
    }
    
    // 表示するアイテムを決定（ピン留め優先）
    static func getDisplayItem() -> WidgetItemData? {
        print("🎯 Widget: 表示アイテム決定開始")
        
        // ピン留めアイテムを優先
        if let pinnedItem = getPinnedItem() {
            print("✅ Widget: ピン留めアイテムを表示: \(pinnedItem.title)")
            return pinnedItem
        }
        
        // ピン留めがない場合は次の期限
        if let upcomingItem = getUpcomingItem() {
            print("✅ Widget: 次期限アイテムを表示: \(upcomingItem.title)")
            return upcomingItem
        }
        
        print("❌ Widget: 表示できるアイテムがありません")
        return nil
    }
    
    // 強制データ更新とテスト
    static func testDataAccess() {
        print("🧪 Widget: データアクセステスト開始")
        
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Test: UserDefaults アクセス失敗")
            return
        }
        
        // テストデータを書き込み
        let testData = "test".data(using: .utf8)!
        userDefaults.set(testData, forKey: "test")
        userDefaults.synchronize()
        
        // テストデータを読み込み
        if let _ = userDefaults.data(forKey: "test") {
            print("✅ Test: データ読み書き成功")
        } else {
            print("❌ Test: データ読み書き失敗")
        }
        
        // 実際のデータを確認
        if let actualData = userDefaults.data(forKey: dataKey) {
            print("✅ Test: 実際のデータ存在 - \(actualData.count) bytes")
        } else {
            print("❌ Test: 実際のデータなし")
        }
        
        print("🧪 Widget: データアクセステスト完了")
    }
}

// ───── Provider ─────
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            daysLeft: 7,
            itemTitle: "サンプルタスク",
            isPinned: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        print("📸 Widget: スナップショット取得")
        
        // データアクセステストを実行
        WidgetDataManager.testDataAccess()
        
        let entry = makeEntry(for: .now)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        print("🔄 Widget: タイムライン更新開始")
        print("🔄 Widget: Context: \(context)")
        
        // データアクセステストを実行
        WidgetDataManager.testDataAccess()
        
        let now = Date()
        let entries: [SimpleEntry] = (0..<5).map { offset in
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset * 10, to: now) ?? now
            return makeEntry(for: entryDate)
        }
        
        // 10分後に次の更新（テスト用に短縮）
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        
        print("🔄 Widget: タイムライン更新完了 - \(entries.count) エントリ")
        for (index, entry) in entries.enumerated() {
            print("Entry[\(index)]: \(entry.debugDescription)")
        }
        
        completion(timeline)
    }

    private func makeEntry(for date: Date) -> SimpleEntry {
        print("📊 Widget: エントリ作成開始 - \(date.formatted(date: .abbreviated, time: .shortened))")
        
        if let displayItem = WidgetDataManager.getDisplayItem() {
            let entry = SimpleEntry(
                date: date,
                daysLeft: displayItem.daysRemaining,
                itemTitle: displayItem.title,
                isPinned: displayItem.isPinned
            )
            
            print("✅ Widget: エントリ作成成功 - \(displayItem.title) (\(displayItem.daysRemaining)日) ピン:\(displayItem.isPinned)")
            return entry
        }
        
        print("❌ Widget: データなし - 空のエントリを作成")
        return SimpleEntry(date: date, daysLeft: nil, itemTitle: nil, isPinned: false)
    }
}

// ───── Entry ─────
struct SimpleEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int?
    let itemTitle: String?
    let isPinned: Bool
    
    // デバッグ用
    var debugDescription: String {
        if let title = itemTitle, let days = daysLeft {
            return "\(title) - \(days)日 - ピン: \(isPinned)"
        } else {
            return "データなし"
        }
    }
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
                    if entry.isPinned && showPinIndicator(for: family) {
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
                        
                        Text(daysLabel(for: days))
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
                        
                        VStack(spacing: 4) {
                            Text("タスクなし")
                                .font(noDataFont(for: family))
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            if family != .systemSmall {
                                Text("App Groups設定を確認")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
            }
            .padding(paddingSize(for: family))
        }
        .onAppear {
            print("🎨 Widget View: 表示開始")
            print("🎨 Widget View: エントリ内容: \(entry.debugDescription)")
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
    
    // MARK: - Helper Functions
    
    private func daysLabel(for days: Int) -> String {
        if days < 0 {
            return "日経過"
        } else if days == 0 {
            return "今日"
        } else {
            return "日後"
        }
    }
    
    private func showPinIndicator(for family: WidgetFamily) -> Bool {
        switch family {
        case .systemSmall:
            return false
        default:
            return true
        }
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
                .containerBackground(.fill.tertiary, for: .widget)
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

#Preview(as: .systemMedium) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now, daysLeft: 7, itemTitle: "重要な会議の準備", isPinned: true)
    SimpleEntry(date: .now, daysLeft: nil, itemTitle: nil, isPinned: false)
}
