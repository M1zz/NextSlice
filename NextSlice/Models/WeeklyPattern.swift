import Foundation
import SwiftData

/// One row per ISO-week. Captures the user's pattern-of-the-week (a Finding-of-Findings)
/// plus their response to the active-recall card.
@Model
final class WeeklyPattern {
    /// Start of the ISO week (Monday 00:00). Treat as primary key.
    var weekStart: Date

    /// Free-form one-liner the user writes at the bottom of the weekly retro.
    var pattern: String

    /// Snapshot text of the recalled finding (kept even if the source Finding is deleted).
    var recalledFindingText: String?
    var recalledFindingSourceDate: Date?
    var recallResponse: String?

    var completedAt: Date?

    init(weekStart: Date, pattern: String = "") {
        self.weekStart = weekStart
        self.pattern = pattern
    }
}
