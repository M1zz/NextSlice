import SwiftUI

/// Visual indicator of where the user sits on the gradient enforcement curve.
struct TrustGaugeView: View {
    let stage: UserStage

    private var progress: Double {
        let day = Double(stage.daysSinceStart)
        return min(1.0, day / 30.0)
    }

    private var nextThresholdHint: String {
        let day = stage.daysSinceStart
        switch day {
        case ..<7:  return "Medium starts on day 8 (\(7 - day) days)"
        case 7..<21: return "Hard starts on day 22 (\(21 - day) days)"
        default:    return "Fully self-disciplined."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Trust gauge · Day \(stage.daysSinceStart + 1)",
                      systemImage: "shield.checkered")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                Spacer()
                Text(stage.currentMode.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.15))
                    Capsule()
                        .fill(.tint)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            Text(nextThresholdHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}
