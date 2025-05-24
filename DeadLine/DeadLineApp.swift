//
//  DeadLineApp.swift
//  DeadLine
//
//  Created by kota on 2025/05/15.
//

import SwiftUI
import RealmSwift

@main
struct DeadLineApp: SwiftUI.App {
    init() {
        configureRealm()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                // マイグレーションが必要な場合に記述
            }
        )
        Realm.Configuration.defaultConfiguration = config
    }
}
