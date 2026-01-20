import WidgetKit
import SwiftUI

// Note: @main is in RoastMeLaterWidgetBundle.swift
// This file only contains the RoastWidget implementation

struct RoastWidget: Widget {
    let kind: String = "RoastWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoastWidgetProvider()) { entry in
            RoastWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Roast của ngày")
        .description("Xem roast mới nhất và streak của bạn")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Entry
struct RoastWidgetEntry: TimelineEntry {
    let date: Date
    let roastData: WidgetRoastData

    static var placeholder: RoastWidgetEntry {
        RoastWidgetEntry(date: Date(), roastData: .placeholder)
    }
}

// MARK: - Timeline Provider
struct RoastWidgetProvider: TimelineProvider {
    private let appGroupIdentifier = "group.com.roastmelater"
    private let widgetDataKey = "widget_roast_data"

    func placeholder(in context: Context) -> RoastWidgetEntry {
        RoastWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RoastWidgetEntry) -> Void) {
        let entry = RoastWidgetEntry(date: Date(), roastData: loadRoastData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoastWidgetEntry>) -> Void) {
        let currentDate = Date()
        let nextRefresh = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400))

        let entry = RoastWidgetEntry(date: currentDate, roastData: loadRoastData())
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadRoastData() -> WidgetRoastData {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: widgetDataKey),
              let roastData = try? JSONDecoder().decode(WidgetRoastData.self, from: data) else {
            return .empty
        }
        return roastData
    }
}

// MARK: - Widget Data Model (Shared with main app)
// WidgetRoastData is defined in the shared framework or copied here for widget target
struct WidgetRoastData: Codable {
    let roastOfTheDay: String
    let category: String
    let categoryIcon: String
    let spiceLevel: Int
    let generatedDate: Date
    let currentStreak: Int

    static var placeholder: WidgetRoastData {
        WidgetRoastData(
            roastOfTheDay: "Bạn đẹp trai/xinh gái đến mức gương cũng phải ghen tị! 🔥",
            category: "general",
            categoryIcon: "flame.fill",
            spiceLevel: 3,
            generatedDate: Date(),
            currentStreak: 7
        )
    }

    static var empty: WidgetRoastData {
        WidgetRoastData(
            roastOfTheDay: "Chưa có roast nào. Mở app để tạo roast đầu tiên!",
            category: "general",
            categoryIcon: "flame.fill",
            spiceLevel: 1,
            generatedDate: Date(),
            currentStreak: 0
        )
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    RoastWidget()
} timeline: {
    RoastWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    RoastWidget()
} timeline: {
    RoastWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    RoastWidget()
} timeline: {
    RoastWidgetEntry.placeholder
}

