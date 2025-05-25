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
}
