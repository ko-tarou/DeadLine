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
                        Text("ピン留めされたアイテムがありません")
                            .foregroundColor(.secondary)
                            .padding()
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
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                AddButtonView {
                    showingAddItemModal = true
                }
                .padding()
            }
        }
        .onAppear {
            // 初回表示時にWidget データを更新
            updateWidgetData()
        }
        .onChange(of: items) { _, _ in
            // アイテムが変更されたらWidget データを更新
            updateWidgetData()
        }
        .sheet(isPresented: $showingAddItemModal) {
            AddItemView()
                .onDisappear {
                    // モーダル閉じた時にWidget データを更新
                    updateWidgetData()
                }
        }
        .sheet(item: $selectedItem) { item in
            ShowItemView(item: item)
                .onDisappear {
                    // 詳細画面閉じた時にWidget データを更新
                    updateWidgetData()
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func togglePinItem(_ item: DeadlineItem) {
        // 他のアイテムのピンを外す
        for existingItem in items {
            if existingItem.isPinned && existingItem.id != item.id {
                existingItem.isPinned = false
            }
        }
        
        // 選択されたアイテムのピン状態をトグル
        item.isPinned.toggle()
        
        // 変更を保存
        do {
            try modelContext.save()
            print("ピン切り替え完了: \(item.title)")
        } catch {
            print("ピン切り替えエラー: \(error)")
        }
        
        // Widget データを更新
        updateWidgetData()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]
                print("削除予定: \(item.title)")
                modelContext.delete(item)
            }
            
            do {
                try modelContext.save()
                print("削除完了")
            } catch {
                print("削除エラー: \(error)")
            }
        }
        
        // Widget データを更新
        updateWidgetData()
    }
    
    // MARK: - Widget Data Sync
    
    private func updateWidgetData() {
        guard let userDefaults = UserDefaults(suiteName: "group.deadline.shared") else {
            print("⚠️ App Group UserDefaults にアクセスできません")
            return
        }
        
        // 現在のアイテムをWidget用データに変換
        let widgetData = items.map { item in
            WidgetItemData(
                title: item.title,
                date: item.date,
                memo: item.memo,
                isPinned: item.isPinned
            )
        }
        
        do {
            let data = try JSONEncoder().encode(widgetData)
            userDefaults.set(data, forKey: "widgetData")
            
            // Widget を更新
            WidgetCenter.shared.reloadAllTimelines()
            
            print("✅ Widget データ更新完了: \(widgetData.count) 件")
            
            // デバッグ情報
            if let pinnedData = widgetData.first(where: { $0.isPinned }) {
                print("📌 ピン留めアイテム: \(pinnedData.title)")
            }
            
        } catch {
            print("❌ Widget データエンコードエラー: \(error)")
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
                
                Button("編集") {
                    // 編集機能は後で実装
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
        item.isPinned = false
        do {
            try modelContext.save()
            onPinToggle() // コールバック実行
            print("ピン解除完了: \(item.title)")
        } catch {
            print("ピン解除エラー: \(error)")
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
