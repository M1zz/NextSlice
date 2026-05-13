import SwiftUI
import SwiftData

/// Reachable from a gear icon on Today / Week. Lets the user manually override
/// the stage — autonomy is part of the philosophy.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var stages: [UserStage]

    var body: some View {
        NavigationStack {
            Form {
                if let stage = stages.first {
                    Section {
                        LabeledContent("일차", value: "\(stage.daysSinceStart + 1)")
                        LabeledContent("자동 단계", value: autoStageLabel(stage))
                    } header: {
                        Text("신뢰 게이지")
                    }

                    Section {
                        Picker("수동 설정", selection: overrideBinding(stage)) {
                            Text("자동").tag(StageMode?.none)
                            ForEach(StageMode.allCases) { mode in
                                Text(mode.label).tag(StageMode?.some(mode))
                            }
                        }

                        if let m = stage.manualOverride {
                            Text(m.blurb)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(stage.currentMode.blurb)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("강제 단계")
                    } footer: {
                        Text("자동은 자연 곡선을 따라요: 소프트(1–7일), 미디엄(8–21일), 하드(22일+). 필요할 땐 직접 바꿔도 좋아요.")
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func overrideBinding(_ stage: UserStage) -> Binding<StageMode?> {
        Binding(
            get: { stage.manualOverride },
            set: { newValue in
                stage.manualOverride = newValue
                try? context.save()
            }
        )
    }

    private func autoStageLabel(_ stage: UserStage) -> String {
        switch stage.daysSinceStart {
        case ..<7:  return "소프트"
        case ..<21: return "미디엄"
        default:    return "하드"
        }
    }
}
