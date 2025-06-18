//
//  DeadLineApp.swift
//  DeadLine
//
//  Created by kota on 2025/05/15.
//

import SwiftUI
import SwiftData

@main
struct DeadLineApp: SwiftUI.App {
    
    init() {
        // デバッグ情報の出力
        SwiftDataConfig.printDatabaseInfo()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(SwiftDataConfig.createSharedModelContainer(DeadlineItem.self))
        }
    }
}
