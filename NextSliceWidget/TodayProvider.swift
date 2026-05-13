import WidgetKit
import SwiftData
import Foundation

/// Reads the current day's intent from the shared SwiftData container.
struct TodayProvider: TimelineProvider {
    typealias Entry = TodayWidgetEntry

    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(
            date: .now,
            intent: "오늘의 한 조각",
            isReflectionPending: false,
            dayNumber: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh roughly every 30 minutes; widget also refreshes when the app saves.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    // MARK: - Load

    private func loadEntry() -> TodayWidgetEntry {
        let schema = Schema([DailyEntry.self, UserStage.self, Finding.self, WeeklyPattern.self])

        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            return TodayWidgetEntry.empty
        }
        let storeURL = groupURL.appendingPathComponent("NextSlice.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            // Today
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today
            var todayDesc = FetchDescriptor<DailyEntry>(
                predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
            )
            todayDesc.fetchLimit = 1
            let todayEntry = try? context.fetch(todayDesc).first

            // Yesterday open?
            let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
            var yDesc = FetchDescriptor<DailyEntry>(
                predicate: #Predicate { $0.date >= yesterday && $0.date < today }
            )
            yDesc.fetchLimit = 1
            let yesterdayEntry = try? context.fetch(yDesc).first
            let pending = (yesterdayEntry != nil) && (yesterdayEntry?.isReflectionComplete == false)

            // Stage
            let stages = (try? context.fetch(FetchDescriptor<UserStage>())) ?? []
            let stage = stages.first
            let day = (stage?.daysSinceStart ?? 0) + 1

            return TodayWidgetEntry(
                date: .now,
                intent: todayEntry?.intent ?? "오늘의 한 조각을 정해주세요",
                isReflectionPending: pending,
                dayNumber: day
            )
        } catch {
            return TodayWidgetEntry.empty
        }
    }
}

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let intent: String
    let isReflectionPending: Bool
    let dayNumber: Int

    static let empty = TodayWidgetEntry(
        date: .now,
        intent: "NextSlice를 열어 시작해주세요",
        isReflectionPending: false,
        dayNumber: 1
    )
}

enum AppGroup {
    /// Must match the main app's identifier. Configure App Groups capability on both targets.
    static let identifier = "group.com.devkoan.NextSlice"
}
