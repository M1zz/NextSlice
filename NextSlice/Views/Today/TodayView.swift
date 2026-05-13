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
    /// All goals ever created — including archived ones. Used to decide whether
    /// the user has ever passed through the goal-setting wizard.
    @Query private var anyTimeGoals: [Goal]

    @State private var showDeleteConfirm: Bool = false

    private var todayEntry: DailyEntry? {
        let today = Date.now.dayStart
        return entries.first {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

    private var mode: TodayMode {
        let hour = Calendar.current.component(.hour, from: .now)
        let isEvening = hour >= 18
        let baseMode: TodayMode = {
            switch (isEvening, todayEntry, todayEntry?.isReflectionComplete ?? false) {
            case (false, .none, _):     return .morning
            case (false, .some, _):     return .active
            case (true,  .none, _):     return .morning
            case (true,  .some, true):  return .completed
            case (true,  .some, false): return .evening
            }
        }()
        // Gate: if the user is about to write today's intent but has never set
        // up a goal, route them through the onboarding first.
        if baseMode == .morning && anyTimeGoals.isEmpty {
            return .needsGoal
        }
        return baseMode
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .needsGoal:
                    GoalOnboardingView()
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
            .toolbar {
                if todayEntry != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("오늘 기록 삭제", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog(
                "오늘 기록을 삭제할까요?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) { deleteToday() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("오늘 작성한 의도와 메모, 그리고 오늘 회고에서 만든 Finding이 함께 사라져요. 되돌릴 수 없습니다.")
            }
        }
    }

    private func deleteToday() {
        guard let entry = todayEntry else { return }

        // Remove any Finding promoted from this entry (sourceEntry backlink).
        let today = entry.date
        var fdesc = FetchDescriptor<Finding>(
            predicate: #Predicate { $0.sourceDate == today }
        )
        fdesc.fetchLimit = 16
        if let findings = try? context.fetch(fdesc) {
            for f in findings where f.sourceEntry == entry {
                context.delete(f)
            }
        }

        context.delete(entry)
        try? context.save()
    }
}

enum TodayMode {
    case needsGoal, morning, active, evening, completed
}
