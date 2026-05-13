import Foundation
import SwiftData

/// A Finding is the long-term, searchable artifact extracted from a day's
/// reflection. Findings are the only thing that survive past their day.
///
/// They are surfaced two ways:
/// 1. Notebook view (always available, but no proactive recall).
/// 2. Weekly retrospective — `ReflectionRecallService` pulls one for active recall.
@Model
final class Finding {
    var text: String
    var tags: [String]
    var sourceDate: Date
    var lastReviewedAt: Date?

    /// Backlink — when present, lets us jump from a Finding back to the day card.
    var sourceEntry: DailyEntry?

    init(
        text: String,
        tags: [String] = [],
        sourceDate: Date,
        sourceEntry: DailyEntry? = nil
    ) {
        self.text = text
        self.tags = tags
        self.sourceDate = sourceDate
        self.sourceEntry = sourceEntry
    }

    /// Days since this finding was created.
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: sourceDate, to: .now).day ?? 0
    }

    /// Distance (in days) to the nearest recall milestone.
    /// Used by ReflectionRecallService to pick "ripe" findings on weekly retro.
    var milestoneDistance: Int {
        let milestones = [30, 60, 90, 180, 365]
        return milestones.map { abs($0 - ageInDays) }.min() ?? Int.max
    }
}
