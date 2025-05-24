//
//  DeadLineWidget.swift
//  DeadLineWidget
//
//  Created by kota on 2025/05/22.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct DeadLineWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
                .font(timeFontForFamily(family))
        }
    }
    
    func timeFontForFamily(_ family: WidgetFamily) -> Font {
            switch family {
            case .systemSmall:
                // 小さいサイズには少し大きめのフォント
                return .system(size: 30, weight: .medium, design: .rounded)
            case .systemMedium:
                // 中サイズにはさらに大きなフォント
                return .system(size: 50, weight: .bold, design: .rounded)
            case .systemLarge:
                // 大サイズには最も大きなフォント
                return .system(size: 70, weight: .bold, design: .rounded)
            case .systemExtraLarge: // iPadOS のみ
                 return .system(size: 90, weight: .bold, design: .rounded)
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                return .caption // 例として caption を使用
            @unknown default:
                // 未知のサイズの場合のデフォルト
                return .body
            }
        }
}

struct DeadLineWidget: Widget {
    let kind: String = "DeadLineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            DeadLineWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemLarge) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now)
}

