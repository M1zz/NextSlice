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
                        LabeledContent("Day", value: "\(stage.daysSinceStart + 1)")
                        LabeledContent("Auto stage", value: autoStageLabel(stage))
                    } header: {
                        Text("Trust gauge")
                    }

                    Section {
                        Picker("Manual override", selection: overrideBinding(stage)) {
                            Text("Auto").tag(StageMode?.none)
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
                        Text("Enforcement")
                    } footer: {
                        Text("Auto follows the natural gradient: Soft (1–7), Medium (8–21), Hard (22+). Override at your discretion.")
                    }
                }
            }
            .navigationTitle("Settings")
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
        case ..<7:  return "Soft"
        case ..<21: return "Medium"
        default:    return "Hard"
        }
    }
}
