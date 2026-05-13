import Foundation
import SwiftData

/// Implements the gradient feedback-loop enforcement.
///
/// The service is intentionally read-only on UserStage — the stage advances by
/// the calendar, not by user actions. The only writes happen via
/// `stage.manualOverride = …` from the Settings screen.
@Observable
final class EnforcementService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Returns yesterday's DailyEntry iff it exists AND its reflection is incomplete.
    /// Returns nil if there was no entry yesterday or it was fully closed.
    func unfinishedYesterday() -> DailyEntry? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
              let dayAfter = cal.date(byAdding: .day, value: 1, to: yesterday)
        else { return nil }

        var descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= yesterday && entry.date < dayAfter
            }
        )
        descriptor.fetchLimit = 1

        guard let entry = try? context.fetch(descriptor).first else { return nil }
        return entry.isReflectionComplete ? nil : entry
    }

    /// Whether the user is allowed to create a new intent today, given the stage.
    func canStartNewIntent(stage: UserStage) -> Bool {
        guard unfinishedYesterday() != nil else { return true }
        return stage.currentMode.allowsSkippingReflection
    }

    /// Should the morning screen present a "finish yesterday first" sheet?
    /// (Distinct from `canStartNewIntent` — Medium prompts but allows override.)
    func shouldPromptForYesterday(stage: UserStage) -> Bool {
        guard unfinishedYesterday() != nil else { return false }
        return stage.currentMode.promptsReflectionFirst
    }

    /// Today's entry, if it exists.
    func todayEntry() -> DailyEntry? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return nil }

        var descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
