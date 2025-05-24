//
//  HomeViewModel.swift
//  DeadLine
//
//  Created by 三ツ井渚 on 2025/05/21.
//
import Foundation
import RealmSwift

class HomeViewModel: ObservableObject {
    @Published var items: [DeadlineItem] = []
    @Published var pinnedItem: DeadlineItem? = nil
    
    func fetchItems() {
        do {
            let realm = try Realm()
            let results = realm.objects(DeadlineItem.self)
            items = Array(results)
        } catch {
            print("Realm読み込みエラー: \(error.localizedDescription)")
            items = []
        }
    }

    
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
    }

    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    func addItem(title: String, date: Date, memo: String) {
        let newItem = DeadlineItem()
        newItem.title = title
        newItem.date = date
        newItem.memo = memo

        let realm = try! Realm()
        try! realm.write {
            realm.add(newItem)
        }

        fetchItems() // 保存後に一覧更新
    }
    
    func deleteItem(_ item: DeadlineItem) {
        let realm = try! Realm()
        if let objectToDelete = realm.object(ofType: DeadlineItem.self, forPrimaryKey: item.id) {
            try! realm.write {
                realm.delete(objectToDelete)
            }
            fetchItems() // 削除後にリストを更新
        }
    }
    
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
    }

}

