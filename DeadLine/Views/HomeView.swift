//
//  HomeView.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/19.
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Widget用データ転送構造体
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

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: \DeadlineItem.createdDate,
        order: .reverse
    ) private var items: [DeadlineItem]
    
    @State private var showingAddItemModal = false
    @State private var selectedItem: DeadlineItem? = nil
    @State private var isShowingDetailSheet = false
    @State private var showingDebugInfo = false
    
    // App Groups 設定
    private let appGroupId = "group.deadline.app.shared"
    private let dataKey = "widgetData"
    
    // ピン留めされたアイテムを計算プロパティとして取得
    private var pinnedItem: DeadlineItem? {
        items.first { $0.isPinned }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Header & Top View
                    if let currentPinnedItem = pinnedItem {
                        TopView(item: currentPinnedItem, modelContext: modelContext) {
                            // ピン解除時のコールバック
                            updateWidgetData()
                        }
                    } else {
                        EmptyPinnedView()
                    }
                    
                    // Items List
                    List {
                        ForEach(items) { item in
                            let isCurrentItemPinned = item.isPinned
                            
                            ZStack(alignment: .topLeading) {
                                CountItem(
                                    title: item.title,
                                    date: item.date.formatted(date: .abbreviated, time: .omitted),
                                    days: item.daysRemaining,
                                    isPin: isCurrentItemPinned
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                selectedItem = item
                                isShowingDetailSheet = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    togglePinItem(item)
                                } label: {
                                    Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    
                    // Debug Info (開発時のみ)
                    #if DEBUG
                    if showingDebugInfo {
                        DebugInfoView(items: items, appGroupId: appGroupId, dataKey: dataKey)
                    }
                    #endif
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                HStack {
                    #if DEBUG
                    // デバッグボタン
                    Button {
                        showingDebugInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
                    #endif
                    
                    Spacer()
                    
                    AddButtonView {
                        showingAddItemModal = true
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("App Groups確認") {
                        checkAppGroupsConfiguration()
                    }
                    .font(.caption)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Widget更新") {
                        forceUpdateWidget()
                    }
                    .font(.caption)
                }
            }
        }
        .onAppear {
            print("🏠 HomeView: 画面表示")
            checkAppGroupsConfiguration()
            // 初回表示時にWidget データを更新
            updateWidgetData()
        }
        .onChange(of: items) { oldItems, newItems in
            print("🔄 HomeView: アイテム変更検出 - 旧:\(oldItems.count) 新:\(newItems.count)")
            // アイテムが変更されたらWidget データを更新
            updateWidgetData()
        }
        .sheet(isPresented: $showingAddItemModal) {
            AddItemView()
                .onDisappear {
                    print("➕ HomeView: 追加モーダル閉じた")
                    // モーダル閉じた時にWidget データを更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        updateWidgetData()
                    }
                }
        }
        .sheet(item: $selectedItem) { item in
            ShowItemView(item: item)
                .onDisappear {
                    print("👁️ HomeView: 詳細画面閉じた")
                    // 詳細画面閉じた時にWidget データを更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        updateWidgetData()
                    }
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func togglePinItem(_ item: DeadlineItem) {
        print("📌 HomeView: ピン切り替え開始 - \(item.title)")
        
        // 他のアイテムのピンを外す
        for existingItem in items {
            if existingItem.isPinned && existingItem.id != item.id {
                existingItem.isPinned = false
                print("📌 HomeView: ピン解除 - \(existingItem.title)")
            }
        }
        
        // 選択されたアイテムのピン状態をトグル
        let newPinState = !item.isPinned
        item.isPinned = newPinState
        
        print("📌 HomeView: ピン状態変更 - \(item.title): \(newPinState)")
        
        // 変更を保存
        do {
            try modelContext.save()
            print("✅ HomeView: ピン切り替え保存完了")
        } catch {
            print("❌ HomeView: ピン切り替えエラー: \(error)")
        }
        
        // Widget データを更新
        updateWidgetData()
    }
    
    private func deleteItems(offsets: IndexSet) {
        print("🗑️ HomeView: 削除開始")
        
        withAnimation {
            var deletedTitles: [String] = []
            
            for index in offsets {
                let item = items[index]
                deletedTitles.append(item.title)
                print("🗑️ HomeView: 削除予定 - \(item.title)")
                modelContext.delete(item)
            }
            
            do {
                try modelContext.save()
                print("✅ HomeView: 削除完了 - \(deletedTitles.joined(separator: ", "))")
            } catch {
                print("❌ HomeView: 削除エラー: \(error)")
            }
        }
        
        // Widget データを更新
        updateWidgetData()
    }
    
    // MARK: - App Groups Configuration Check
    
    private func checkAppGroupsConfiguration() {
        print("🔧 HomeView: App Groups 設定確認開始")
        print("🔧 HomeView: App Group ID: \(appGroupId)")
        
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ HomeView: App Groups UserDefaults にアクセスできません")
            print("❌ HomeView: 以下を確認してください:")
            print("   1. メインアプリのApp Groups設定")
            print("   2. Widget ExtensionのApp Groups設定")
            print("   3. App Group ID: \(appGroupId)")
            return
        }
        
        print("✅ HomeView: App Groups UserDefaults アクセス成功")
        
        // テストデータの書き込み・読み込み
        let testKey = "appGroupTest"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        userDefaults.set(testValue, forKey: testKey)
        userDefaults.synchronize()
        
        if let retrievedValue = userDefaults.string(forKey: testKey),
           retrievedValue == testValue {
            print("✅ HomeView: App Groups データ読み書きテスト成功")
        } else {
            print("❌ HomeView: App Groups データ読み書きテスト失敗")
        }
        
        // 既存のWidget データ確認
        if let existingData = userDefaults.data(forKey: dataKey) {
            print("📦 HomeView: 既存Widget データ: \(existingData.count) bytes")
        } else {
            print("📦 HomeView: 既存Widget データなし")
        }
        
        print("🔧 HomeView: App Groups 設定確認完了")
    }
    
    // MARK: - Widget Data Sync (Step 1: 強制同期対応)
    
    private func updateWidgetData() {
        print("🔄 HomeView: Widget データ更新開始")
        print("🔄 HomeView: 使用App Group ID: \(appGroupId)")
        
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ HomeView: App Group UserDefaults アクセス失敗")
            return
        }
        
        print("✅ HomeView: App Groups UserDefaults アクセス成功")
        
        // 現在のアイテムをWidget用データに変換
        let widgetData = items.map { item in
            WidgetItemData(
                title: item.title,
                date: item.date,
                memo: item.memo,
                isPinned: item.isPinned
            )
        }
        
        print("📊 HomeView: 変換データ数: \(widgetData.count)")
        for (index, item) in widgetData.enumerated() {
            print("📊 HomeView[\(index)]: \(item.title) - ピン: \(item.isPinned)")
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(widgetData)
            
            print("📦 HomeView: エンコード完了 - \(data.count) bytes")
            
            // 既存データを削除してから新規保存
            userDefaults.removeObject(forKey: dataKey)
            userDefaults.synchronize()
            print("🗑️ HomeView: 既存データ削除完了")
            
            // データを保存
            userDefaults.set(data, forKey: dataKey)
            
            // 複数回同期を試行
            for i in 1...5 {
                let syncResult = userDefaults.synchronize()
                print("📱 HomeView: 同期試行\(i): \(syncResult)")
                Thread.sleep(forTimeInterval: 0.2) // 少し長めに待機
            }
            
            // 保存確認
            if let savedData = userDefaults.data(forKey: dataKey) {
                print("✅ HomeView: データ保存確認 - \(savedData.count) bytes")
                
                // 保存されたデータの内容確認
                let hexString = savedData.map { String(format: "%02x", $0) }.joined()
                print("📦 HomeView: 保存データ(hex): \(String(hexString.prefix(100)))...")
                
                // デコードテスト
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedData = try decoder.decode([WidgetItemData].self, from: savedData)
                    print("✅ HomeView: デコードテスト成功 - \(decodedData.count) 件")
                    
                    for (index, item) in decodedData.enumerated() {
                        print("📦 HomeView デコード[\(index)]: \(item.title) - ピン: \(item.isPinned)")
                    }
                    
                } catch {
                    print("❌ HomeView: デコードテストエラー: \(error)")
                }
                
            } else {
                print("❌ HomeView: データ保存失敗 - 保存確認でデータが見つからない")
            }
            
            // 追加確認：すべてのキーを表示
            let allKeys = userDefaults.dictionaryRepresentation().keys
            print("📱 HomeView: 保存後の全キー: \(Array(allKeys))")
            
            // Widget を更新
            WidgetCenter.shared.reloadAllTimelines()
            
            print("✅ HomeView: Widget データ更新完了 - \(widgetData.count) 件")
            
        } catch {
            print("❌ HomeView: Widget データエンコードエラー: \(error)")
        }
    }

    
    private func forceUpdateWidget() {
        print("🔄 HomeView: 強制Widget更新")
        updateWidgetData()
        
        // 少し遅延してもう一度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 HomeView: 遅延Widget更新完了")
        }
    }
    
    // MARK: - Debug Methods
    
    private func printItemsDebugInfo() {
        print("=== アイテム一覧 ===")
        for (index, item) in items.enumerated() {
            print("\(index + 1). \(item.title) - \(item.daysRemaining)日 - ピン: \(item.isPinned)")
        }
        print("==================")
    }
}

// MARK: - Empty Pinned View

struct EmptyPinnedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pin.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("ピン留めされたアイテムがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("アイテムを左にスワイプしてピン留めできます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 1)
    }
}

// MARK: - Debug Info View

#if DEBUG
struct DebugInfoView: View {
    let items: [DeadlineItem]
    let appGroupId: String
    let dataKey: String
    
    @State private var widgetDataInfo: String = "確認中..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🐛 デバッグ情報")
                .font(.headline)
                .foregroundColor(.orange)
            
            Group {
                Text("総アイテム数: \(items.count)")
                Text("ピン留め数: \(items.filter { $0.isPinned }.count)")
                
                if let pinnedItem = items.first(where: { $0.isPinned }) {
                    Text("ピン留めアイテム: \(pinnedItem.title)")
                    Text("残り日数: \(pinnedItem.daysRemaining)日")
                } else {
                    Text("ピン留めアイテム: なし")
                }
                
                Text("App Group ID: \(appGroupId)")
                Text("Data Key: \(dataKey)")
                Text("Widget データ: \(widgetDataInfo)")
            }
            .font(.caption)
            
            HStack {
                Button("Widget強制更新") {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("データ確認") {
                    checkWidgetData()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            checkWidgetData()
        }
    }
    
    private func checkWidgetData() {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let data = userDefaults.data(forKey: dataKey) else {
            widgetDataInfo = "なし"
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([WidgetItemData].self, from: data)
            widgetDataInfo = "\(items.count)件 (\(data.count)bytes)"
        } catch {
            widgetDataInfo = "エラー: \(error.localizedDescription)"
        }
    }
}
#endif

// MARK: - Add Button View

struct AddButtonView: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: { onTap() }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .shadow(radius: 2)
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: 1.0)
    }
}

// MARK: - Top View

struct TopView: View {
    let item: DeadlineItem
    let modelContext: ModelContext
    let onPinToggle: () -> Void // コールバック追加
    
    var body: some View {
        HStack {
            // 左側の円形表示
            ZStack {
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: 130)
                    .overlay {
                        Circle()
                            .stroke(circleBorderColor, lineWidth: 3)
                    }
                
                // 残り日数
                Text("\(item.daysRemaining)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(daysTextColor)
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 6) {
                // ピン留めインジケーター
                HStack {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("ピン留め中")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                // タイトル
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // 日付
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                // ステータス
                Text(item.statusText)
                    .font(.caption)
                    .foregroundColor(statusTextColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // メニューボタン
            Menu {
                Button("ピンを外す") {
                    unpinItem()
                }
                
                Button("詳細を見る") {
                    // 詳細表示機能は後で実装
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var circleBackgroundColor: Color {
        switch item.daysRemaining {
        case ..<0: return .red.opacity(0.1)
        case 0: return .orange.opacity(0.1)
        case 1...3: return .yellow.opacity(0.1)
        case 4...7: return .blue.opacity(0.1)
        default: return .gray.opacity(0.1)
        }
    }
    
    private var circleBorderColor: Color {
        switch item.daysRemaining {
        case ..<0: return .red
        case 0: return .orange
        case 1...3: return .yellow
        case 4...7: return .blue
        default: return .gray
        }
    }
    
    private var daysTextColor: Color {
        switch item.daysRemaining {
        case ..<0: return .red
        case 0: return .orange
        case 1...3: return .yellow
        case 4...7: return .blue
        default: return .primary
        }
    }
    
    private var statusTextColor: Color {
        switch item.daysRemaining {
        case ..<0: return .red
        case 0: return .orange
        case 1...7: return .yellow
        default: return .secondary
        }
    }
    
    private func unpinItem() {
        print("📌 TopView: ピン解除 - \(item.title)")
        item.isPinned = false
        do {
            try modelContext.save()
            onPinToggle() // コールバック実行
            print("✅ TopView: ピン解除完了")
        } catch {
            print("❌ TopView: ピン解除エラー: \(error)")
        }
    }
}

// MARK: - Count Item View

struct CountItem: View {
    let title: String
    let date: String
    let days: Int
    let isPin: Bool
    
    private var itemBackgroundColor: Color {
        if isPin {
            return Color.blue.opacity(0.05)
        } else {
            return Color.white
        }
    }
    
    private var borderColor: Color {
        if isPin {
            return Color.blue.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        ZStack {
            HStack {
                if isPin {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    Text(date)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(days)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(daysColor)
                        
                        Text("日")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(daysColor)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(itemBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var daysColor: Color {
        switch days {
        case ..<0: return .red
        case 0: return .orange
        case 1...3: return .yellow
        case 4...7: return .blue
        default: return .primary
        }
    }
    
    private var statusText: String {
        switch days {
        case ..<0: return "期限切れ"
        case 0: return "今日まで"
        case 1: return "明日まで"
        case 2...7: return "急ぎ"
        default: return ""
        }
    }
}

// MARK: - Previews

#Preview {
    let container = try! ModelContainer(
        for: DeadlineItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // サンプルデータを追加
    let sampleItems = DeadlineItem.sampleData()
    for item in sampleItems {
        container.mainContext.insert(item)
    }
    
    return HomeView()
        .modelContainer(container)
}

#Preview("Empty State") {
    HomeView()
        .modelContainer(for: DeadlineItem.self, inMemory: true)
}
