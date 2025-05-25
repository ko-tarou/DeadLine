//
//  DeadLineWidget.swift
//

import WidgetKit
import SwiftUI
import RealmSwift

// ───── Provider ─────
struct Provider: TimelineProvider {

    // Realm の共通設定を読み込む
    init() { configureRealm() }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, daysLeft: nil, itemTitle: nil)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<SimpleEntry>) -> Void) {

        let now = Date()
        let entries = (0..<5).compactMap { offset -> SimpleEntry in
            let t = Calendar.current.date(byAdding: .hour,
                                          value: offset,
                                          to: now)!
            return makeEntry(for: t)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // MARK: 最も近い DeadlineItem を 1 件取得
    private func makeEntry(for date: Date) -> SimpleEntry {
        do {
            let realm = try Realm()
            // 今日以降の締め切りを期日順で 1 件取得
            if let item = realm.objects(DeadlineItem.self)
                               .filter("date >= %@", Date())
                               .sorted(byKeyPath: "date")
                               .first {

                let days = Calendar.current.dateComponents([.day],
                                                           from: date,
                                                           to: item.date).day
                return SimpleEntry(date: date,
                                   daysLeft: days,
                                   itemTitle: item.title)
            }
        } catch {
            print("Widget-Realm error:", error.localizedDescription)
        }
        // データが無い場合
        return SimpleEntry(date: date, daysLeft: nil, itemTitle: nil)
    }
}

// ───── Entry ─────
struct SimpleEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int?
    let itemTitle: String?
}

// ───── View ─────
struct DeadLineWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading) {
            if let title = entry.itemTitle,
               let days  = entry.daysLeft {
                
                Spacer()

                Text(title)
                    .font(daysFont(for: family))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                HStack {
                    Text("\(days)")
                        .font(daysFont(for: family))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text("day")
                        .font(daysFont(for: family))
                }.frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()

            } else {
                Text("まだ登録\nされていません")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    private func daysFont(for family: WidgetFamily) -> Font {
        switch family {
        case .systemSmall:  .system(size: 30, weight: .bold, design: .rounded)
        case .systemMedium: .system(size: 50, weight: .bold, design: .rounded)
        case .systemLarge:  .system(size: 70, weight: .bold, design: .rounded)
        case .systemExtraLarge: .system(size: 90, weight: .bold, design: .rounded)
        default: .body
        }
    }
}

// ───── Widget ─────
struct DeadLineWidget: Widget {
    let kind = "DeadLineWidget"

    var body: some WidgetConfiguration {
        // 設定不要なので StaticConfiguration を使用
        StaticConfiguration(kind: kind,
                            provider: Provider()) { entry in
            DeadLineWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// ───── Preview ─────
#Preview(as: .systemSmall) {
    DeadLineWidget()
} timeline: {
    SimpleEntry(date: .now, daysLeft: 3, itemTitle: "提出〆切")
    SimpleEntry(date: .now, daysLeft: nil, itemTitle: nil)
}
