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
        case .soft:   return "소프트"
        case .medium: return "미디엄"
        case .hard:   return "하드"
        }
    }

    var blurb: String {
        switch self {
        case .soft:   return "습관 형성기. 건너뛰어도 괜찮아요."
        case .medium: return "회고 안내가 먼저 떠요. 무시할 수도 있어요."
        case .hard:   return "어제를 닫기 전엔 오늘을 시작할 수 없어요."
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
