//
//  ContentView.swift
//  DeadLine
//
//  Created by kota on 2025/05/15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DeadlineItem.self, inMemory: true)
}
