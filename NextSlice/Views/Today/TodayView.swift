import SwiftUI
import SwiftData

/// Today's container. Picks the right mode based on time-of-day and entry state.
///
/// State machine:
///                       no entry          entry exists
///   before 18:00        Morning           DayActive
///   18:00 or later      Evening (no       Evening (4F) → Completed
///                        entry yet → ask
///                        for intent first
///                        then jump to 4F)
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    private var todayEntry: DailyEntry? {
        let today = Date.now.dayStart
        return entries.first {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

    private var mode: TodayMode {
        let hour = Calendar.current.component(.hour, from: .now)
        let isEvening = hour >= 18
        switch (isEvening, todayEntry, todayEntry?.isReflectionComplete ?? false) {
        case (false, .none, _):     return .morning
        case (false, .some, _):     return .active
        case (true,  .none, _):     return .morning   // Still need an intent first
        case (true,  .some, true):  return .completed
        case (true,  .some, false): return .evening
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .morning:
                    MorningModeView()
                case .active:
                    if let entry = todayEntry { DayActiveView(entry: entry) }
                case .evening:
                    if let entry = todayEntry { EveningModeView(entry: entry) }
                case .completed:
                    if let entry = todayEntry { CompletedTodayView(entry: entry) }
                }
            }
            .animation(.default, value: mode)
            .navigationTitle("오늘")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

enum TodayMode {
    case morning, active, evening, completed
}
