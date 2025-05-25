//
//  HomeViewModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//
import Foundation
import RealmSwift
import WidgetKit

class HomeViewModel: ObservableObject {
    @Published var items: [DeadlineItem] = []
    @Published var pinnedItem: DeadlineItem? = nil
    
    // 全Item取得
    func fetchItems() {
        do {
            let realm = try Realm()
            let results = realm.objects(DeadlineItem.self)
            items = Array(results)
            fetchPinnedItem()
        } catch {
            print("Realm読み込みエラー: \(error.localizedDescription)")
            items = []
        }
    }
    
    // ピン留めID取得
    func fetchPinnedItem() {
        do {
            let realm = try Realm()
            if let pinned = realm.objects(PinnedItem.self).first {
                pinnedItem = realm.object(ofType: DeadlineItem.self, forPrimaryKey: pinned.id)
            } else {
                pinnedItem = nil
            }
        } catch {
            print("ピン留めアイテムの取得エラー: \(error.localizedDescription)")
            pinnedItem = nil
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Date型を文字列に変換
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    // 既存のアイテム更新
    func updateItem(id: ObjectId, title: String, date: Date, memo: String) {
        do {
            let realm = try Realm()
            if let existingItem = realm.object(ofType: DeadlineItem.self, forPrimaryKey: id) {
                try realm.write {
                    existingItem.title = title
                    existingItem.date = date
                    existingItem.memo = memo
                }
                fetchItems()
            }
        } catch {
            print("更新エラー: \(error.localizedDescription)")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }

    
    // 追加
    func addItem(title: String, date: Date, memo: String) {
        let newItem = DeadlineItem()
        newItem.title = title
        newItem.date  = date
        newItem.memo  = memo

        do {
            let realm = try Realm()
            try realm.write { realm.add(newItem) }
        } catch {
            // ここに原因が出る
            print("⚠️ Realm WRITE error:", error)
        }

        fetchItems() // 保存後に一覧更新
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // 削除
    func deleteItemById(_ id: ObjectId) {
        DispatchQueue.main.async {
            do {
                let realm = try Realm()
                if let objectToDelete = realm.object(ofType: DeadlineItem.self, forPrimaryKey: id) {
                    try realm.write {
                        realm.delete(objectToDelete)
                    }
                    self.fetchItems()
                }
            } catch {
                print("削除エラー: \(error.localizedDescription)")
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }


    
    // ピン留めアイテムの更新
    func pinItem(_ item: DeadlineItem) {
            let realm = try! Realm()
            
            try! realm.write {
                // すでにピン留めされているものがあれば削除
                let pinnedItems = realm.objects(PinnedItem.self)
                realm.delete(pinnedItems)
                
                // 新たにピン留めアイテムのUUIDを保存
                let pinned = PinnedItem()
                pinned.id = item.id
                realm.add(pinned)
            }
            
        fetchPinnedItem()
        WidgetCenter.shared.reloadAllTimelines()
    }

}

