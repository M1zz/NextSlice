import Foundation
import SwiftData

/// Time-based "trust gauge". Starts Soft, naturally graduates to Medium then Hard.
/// User can also override manually (autonomy is part of Kim Chang-jun's philosophy).
///
/// Gradient (default):
///   Day 1–7   → .soft     (alerts only, skipping allowed)
///   Day 8–21  → .medium   (next morning prompts reflection first, but override visible)
///   Day 22+   → .hard     (new intent locked until yesterday's reflection is done)
@Model
final class UserStage {
    var startDate: Date
    /// Stored as raw string for forward-compatibility with new modes.
    var manualOverrideRaw: String?

    init(startDate: Date = .now) {
        self.startDate = startDate
    }

    var manualOverride: StageMode? {
        get { manualOverrideRaw.flatMap(StageMode.init(rawValue:)) }
        set { manualOverrideRaw = newValue?.rawValue }
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
    }

    var currentMode: StageMode {
        if let override = manualOverride { return override }
        switch daysSinceStart {
        case ..<8:  return .soft
        case ..<22: return .medium
        default:    return .hard
        }
    }
}

enum StageMode: String, Codable, CaseIterable, Identifiable {
    case soft
    case medium
    case hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .soft:   return "Soft"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    var blurb: String {
        switch self {
        case .soft:   return "Forming the habit. Skipping is fine."
        case .medium: return "Reflection prompts first. Override visible."
        case .hard:   return "No new intent until yesterday is closed."
        }
    }

    /// Whether the user can start today's intent without first completing
    /// yesterday's reflection.
    var allowsSkippingReflection: Bool {
        self != .hard
    }

    /// Whether to surface yesterday's reflection as a blocking sheet
    /// when the user arrives at the morning screen.
    var promptsReflectionFirst: Bool {
        self != .soft
    }
}
