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
        case ..<7:   return "8일차부터 미디엄 (앞으로 \(7 - day)일)"
        case 7..<21: return "22일차부터 하드 (앞으로 \(21 - day)일)"
        default:     return "완전 자율 단계."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("신뢰 게이지 · \(stage.daysSinceStart + 1)일차",
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
