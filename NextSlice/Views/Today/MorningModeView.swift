import SwiftUI
import SwiftData

/// The morning prompt. Single-line intent, 80-char hard cap, project optional.
///
/// Before showing the input, checks whether yesterday is still open. If so, and
/// the stage prompts for it, we surface a blocking sheet to close yesterday first.
struct MorningModeView: View {
    @Environment(\.modelContext) private var context
    @Query private var stages: [UserStage]

    @State private var intent = ""
    @State private var project = ""
    @State private var overdueEntry: DailyEntry?
    @State private var showOverdueSheet = false

    private let maxIntent = 80

    private var stage: UserStage { stages.first ?? UserStage() }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if !project.isEmpty {
                projectChip
            }

            Text("What will you learn today?")
                .font(.title2.weight(.medium))
                .padding(.top, 4)

            intentField

            HStack {
                Label("One line only — don't split it.",
                      systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text("\(intent.count) / \(maxIntent)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(intent.count >= maxIntent ? .red : .secondary)
            }

            DisclosureGroup("Project (optional)") {
                TextField("e.g. devkoan, NextSlice, Indonesia trip", text: $project)
                    .textFieldStyle(.roundedBorder)
            }
            .font(.subheadline)

            Spacer()

            startButton
        }
        .padding(20)
        .task { await checkOverdue() }
        .sheet(isPresented: $showOverdueSheet, onDismiss: { Task { await checkOverdue() } }) {
            if let entry = overdueEntry {
                NavigationStack {
                    OverdueReflectionSheet(entry: entry)
                }
                .interactiveDismissDisabled(stage.currentMode == .hard)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("MORNING")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(Date.now, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var projectChip: some View {
        Label(project, systemImage: "target")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.15), in: Capsule())
    }

    private var intentField: some View {
        TextField(
            "SwiftUI Environment로 토큰 주입 패턴 하나 끝까지 시도",
            text: $intent,
            axis: .vertical
        )
        .lineLimit(2...3)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary.opacity(0.3))
        )
        .onChange(of: intent) { _, new in
            // Hard cap. Also strip newlines — one line means one line.
            var trimmed = new.replacingOccurrences(of: "\n", with: " ")
            if trimmed.count > maxIntent {
                trimmed = String(trimmed.prefix(maxIntent))
            }
            if trimmed != new { intent = trimmed }
        }
    }

    private var startButton: some View {
        Button {
            start()
        } label: {
            Text("Start today")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(intent.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - Actions

    @MainActor
    private func checkOverdue() async {
        let svc = EnforcementService(context: context)
        guard let pending = svc.unfinishedYesterday() else {
            overdueEntry = nil
            showOverdueSheet = false
            return
        }
        if svc.shouldPromptForYesterday(stage: stage) {
            overdueEntry = pending
            showOverdueSheet = true
        }
    }

    private func start() {
        let trimmed = intent.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = DailyEntry(
            intent: trimmed,
            project: project.isEmpty ? nil : project
        )
        context.insert(entry)
        try? context.save()
        intent = ""
        project = ""
    }
}

/// Blocking sheet shown when yesterday's reflection wasn't completed.
/// In Hard stage, dismissal is disabled.
struct OverdueReflectionSheet: View {
    let entry: DailyEntry

    var body: some View {
        VStack(spacing: 16) {
            Label("Yesterday is still open", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("Close yesterday before starting today. Short is fine — Finding is the only required field.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            EveningModeView(entry: entry)
        }
        .padding(.top)
    }
}
