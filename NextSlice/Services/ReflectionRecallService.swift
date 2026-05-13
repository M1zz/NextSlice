import Foundation
import SwiftData

/// Picks ONE Finding to surface during the weekly retrospective as the
/// "active recall" card. Strategy:
///
/// 1. Only consider Findings older than the current week.
/// 2. Prefer Findings near a milestone day (30 / 60 / 90 / 180 / 365 days old).
/// 3. Skip Findings reviewed within the last 4 weeks (so the recall feels fresh).
/// 4. Among the rest, pick the one closest to its nearest milestone.
///
/// The user's answer to "does this still apply?" is the most valuable thing
/// the weekly retrospective produces — it's a Finding-of-a-Finding.
struct ReflectionRecallService {
    let context: ModelContext

    /// `weekStart` is the start (Monday 00:00) of the current week.
    /// We only consider Findings strictly older than `weekStart`.
    func pickRecalledFinding(weekStart: Date) -> Finding? {
        let descriptor = FetchDescriptor<Finding>(
            predicate: #Predicate { $0.sourceDate < weekStart },
            sortBy: [SortDescriptor(\.sourceDate, order: .forward)]
        )
        guard let candidates = try? context.fetch(descriptor),
              !candidates.isEmpty else { return nil }

        let now = Date.now
        let cal = Calendar.current

        // Score each finding by milestone proximity + recency penalty.
        // Lower score = better candidate.
        let scored: [(Finding, Int)] = candidates.map { finding in
            let milestoneScore = finding.milestoneDistance

            let recencyPenalty: Int = {
                guard let last = finding.lastReviewedAt else { return 0 }
                let daysSinceReview = cal.dateComponents([.day], from: last, to: now).day ?? 0
                // If reviewed within 4 weeks, push it down hard.
                return daysSinceReview < 28 ? 1000 : 0
            }()

            return (finding, milestoneScore + recencyPenalty)
        }

        return scored.min { $0.1 < $1.1 }?.0
    }
}
