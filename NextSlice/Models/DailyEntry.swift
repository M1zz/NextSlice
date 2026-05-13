import Foundation
import SwiftData

/// One per calendar day. Holds the morning intent and the evening 4F retrospective.
///
/// Design notes:
/// - `intent` is the single "one thing" the user commits to. Hard 80-char limit.
/// - `finding` is the only 4F field that gets promoted to the long-term Notebook.
///   The others (fact, feeling, futureAction) live and die with the day card.
/// - `completedAt` marks when the user finished the evening retro. Used by the
///   EnforcementService to decide whether yesterday is "open".
@Model
final class DailyEntry {

    // Identity
    /// Always normalized to `startOfDay`. Treat as the day's primary key.
    var date: Date

    // Morning
    var intent: String
    var project: String?
    var midNotes: [String]

    // Evening 4F
    var fact: String?
    var feeling: [String]      // Tag chips. Free-form, multi-select.
    var finding: String?
    var futureAction: String?

    // Bookkeeping
    var completedAt: Date?

    init(
        date: Date = Calendar.current.startOfDay(for: .now),
        intent: String,
        project: String? = nil
    ) {
        self.date = date
        self.intent = intent
        self.project = project
        self.midNotes = []
        self.feeling = []
    }

    /// A reflection counts as complete only if a Finding was articulated.
    /// Fact/feeling/futureAction are optional — Finding is the load-bearing one.
    var isReflectionComplete: Bool {
        completedAt != nil && finding?.isEmpty == false
    }
}
