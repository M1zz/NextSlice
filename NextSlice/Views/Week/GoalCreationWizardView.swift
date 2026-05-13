import SwiftUI
import SwiftData

/// Conversational 3-step goal creation. Designed for the case the user has a
/// vague goal in mind but doesn't know how to start — so we *force* the
/// resolution of "what's the smallest first step you could do this weekend?"
/// before the goal can be saved. A goal with zero milestones is, by design,
/// not a goal yet.
struct GoalCreationWizardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { $0.archivedAt == nil })
    private var activeGoals: [Goal]

    @State private var step: Step = .goal
    @State private var goalTitle: String = ""
    @State private var firstTitle: String = ""
    @State private var firstDate: Date = .nextSunday()
    @State private var extras: [DraftMilestone] = []
    @FocusState private var focusedField: WizardField?

    private enum Step: Int { case goal = 0, firstStep = 1, more = 2 }

    private static let palette: [String] = [
        "4FACFE", "FF6B9D", "FFC542", "5DD39E",
        "8B5CF6", "F87171", "38BDF8", "A78BFA"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch step {
                        case .goal:      goalStep
                        case .firstStep: firstStepStep
                        case .more:      moreStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                bottomBar
            }
            .navigationTitle("새 목표")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .onAppear { focusedField = .goal }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.secondary.opacity(0.15))
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .frame(height: 3)
    }

    private var progress: Double {
        switch step {
        case .goal:      return 1.0 / 3.0
        case .firstStep: return 2.0 / 3.0
        case .more:      return 1.0
        }
    }

    // MARK: - Step 1: the goal

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepLabel("1단계")
            Text("어떤 목표를 그리고 있어요?")
                .font(.title2.weight(.semibold))
            Text("아직 추상적이어도 괜찮아요. 다음 단계에서 작게 쪼갤 거예요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(
                "예: SwiftUI로 디자인 시스템 직접 만들기",
                text: $goalTitle,
                axis: .vertical
            )
            .focused($focusedField, equals: .goal)
            .font(.body)
            .lineLimit(2...4)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.top, 4)
        }
    }

    // MARK: - Step 2: first concrete step (mandatory)

    private var firstStepStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepLabel("2단계")
            goalRecap

            Text("이번 주말까지 끝낼 수 있는 작은 한 발은?")
                .font(.title2.weight(.semibold))
                .padding(.top, 4)
            Text("\u{201C}내일 곧장 시작할 수 있을 만큼\u{201D} 작은 게 좋아요. 더 작아도 됩니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(
                "예: '디자인 토큰' 검색해서 좋은 글 한 편 읽기",
                text: $firstTitle,
                axis: .vertical
            )
            .focused($focusedField, equals: .first)
            .font(.body)
            .lineLimit(2...4)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            DatePicker(
                "언제까지",
                selection: $firstDate,
                in: Date.now.dayStart...,
                displayedComponents: .date
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            Label("이 한 줄이 타임라인의 첫 점이 돼요.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    // MARK: - Step 3: optional more milestones

    private var moreStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepLabel("3단계 (선택)")
            goalRecap
            firstRecap

            Text("더 쪼개볼까요?")
                .font(.title2.weight(.semibold))
                .padding(.top, 4)
            Text("지금 떠오르는 게 없다면 그냥 [완료]를 눌러도 좋아요. 나중에 언제든 추가할 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach($extras) { $draft in
                DraftMilestoneRow(
                    draft: $draft,
                    focus: $focusedField,
                    onDelete: { remove(draft) }
                )
            }

            Button {
                addExtra()
            } label: {
                Label("마일스톤 추가", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
    }

    // MARK: - Recaps

    private var goalRecap: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("목표")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(goalTitle)
                .font(.callout.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var firstRecap: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: 14, height: 14)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(firstTitle)
                    .font(.callout)
                Text(firstDate, format: .dateTime.month(.abbreviated).day().weekday(.short))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .goal {
                Button {
                    back()
                } label: {
                    Text("이전")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button {
                next()
            } label: {
                Text(primaryButtonLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canProceed)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    private var primaryButtonLabel: String {
        switch step {
        case .goal:      return "다음"
        case .firstStep: return "다음"
        case .more:      return "완료"
        }
    }

    private var canProceed: Bool {
        switch step {
        case .goal:      return !trimmed(goalTitle).isEmpty
        case .firstStep: return !trimmed(firstTitle).isEmpty
        case .more:      return true
        }
    }

    // MARK: - Helpers

    private func stepLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tint)
    }

    private func next() {
        switch step {
        case .goal:
            withAnimation { step = .firstStep }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedField = .first }
        case .firstStep:
            withAnimation { step = .more }
        case .more:
            commit()
            dismiss()
        }
    }

    private func back() {
        switch step {
        case .goal:      return
        case .firstStep: withAnimation { step = .goal }
        case .more:      withAnimation { step = .firstStep }
        }
    }

    private func addExtra() {
        let newDraft = DraftMilestone(title: "", date: defaultNextDate())
        extras.append(newDraft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedField = .extra(newDraft.id)
        }
    }

    private func remove(_ draft: DraftMilestone) {
        extras.removeAll { $0.id == draft.id }
    }

    private func defaultNextDate() -> Date {
        let cal = Calendar.current
        let base = extras.last?.date ?? firstDate
        return cal.date(byAdding: .day, value: 14, to: base) ?? base
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commit() {
        let goal = Goal(
            title: trimmed(goalTitle),
            colorHex: Self.palette[activeGoals.count % Self.palette.count]
        )
        context.insert(goal)

        let first = Milestone(
            title: trimmed(firstTitle),
            date: firstDate.dayStart,
            goal: goal
        )
        context.insert(first)

        for draft in extras where !trimmed(draft.title).isEmpty {
            let m = Milestone(
                title: trimmed(draft.title),
                date: draft.date.dayStart,
                goal: goal
            )
            context.insert(m)
        }

        try? context.save()
    }
}

// MARK: - Draft milestone row

struct DraftMilestone: Identifiable {
    let id: UUID = UUID()
    var title: String = ""
    var date: Date = .now
}

enum WizardField: Hashable {
    case goal, first, extra(UUID)
}

private struct DraftMilestoneRow: View {
    @Binding var draft: DraftMilestone
    var focus: FocusState<WizardField?>.Binding
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("마일스톤 제목", text: $draft.title)
                    .focused(focus, equals: .extra(draft.id))
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            DatePicker(
                "",
                selection: $draft.date,
                in: Date.now.dayStart...,
                displayedComponents: .date
            )
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Date helper

extension Date {
    /// Upcoming Sunday (this week's). If today is Sunday, returns next Sunday.
    static func nextSunday(from base: Date = .now) -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: base) // 1 = Sun
        var add = (8 - weekday) % 7
        if add == 0 { add = 7 }
        return cal.date(byAdding: .day, value: add, to: base.dayStart) ?? base
    }
}
