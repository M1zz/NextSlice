import SwiftUI
import SwiftData

/// Evening 4F retrospective. Finding is the only required field — everything
/// else is decorative and lives/dies with the day card.
///
/// On submit:
///   1. Sets `entry.completedAt = .now`
///   2. Creates a new `Finding` from the finding text (long-term artifact)
///   3. Optionally pre-fills tomorrow's intent from `futureAction`
struct EveningModeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: DailyEntry

    @State private var fact: String = ""
    @State private var feelingTags: Set<String> = []
    @State private var finding: String = ""
    @State private var futureAction: String = ""

    private let feelingOptions = [
        "막힘", "몰입", "유레카", "지침",
        "헷갈림", "자신감", "호기심", "지루함"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intentRecap

                section(
                    label: "F1 · 사실 (Fact)",
                    hint: "실제로 무엇이 있었나요?"
                ) {
                    TextField(
                        "예: Modifier 주입 시도 → 충돌. EnvironmentValues로 해결.",
                        text: $fact,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }

                section(
                    label: "F2 · 느낌 (Feeling)",
                    hint: nil
                ) {
                    feelingChipRow
                }

                findingSection

                section(
                    label: "F4 · 다음 행동 (Future)",
                    hint: "내일의 의도 후보가 돼요."
                ) {
                    TextField(
                        "예: Color 토큰도 같은 패턴으로 옮기기",
                        text: $futureAction,
                        axis: .vertical
                    )
                    .lineLimit(2...3)
                }

                submitButton
            }
            .padding(20)
        }
        .onAppear { hydrate() }
    }

    private var intentRecap: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 한 가지")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(entry.intent)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var feelingChipRow: some View {
        FlowLayout(spacing: 8) {
            ForEach(feelingOptions, id: \.self) { tag in
                let isOn = feelingTags.contains(tag)
                Button {
                    if isOn { feelingTags.remove(tag) } else { feelingTags.insert(tag) }
                } label: {
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill),
                                    in: Capsule())
                        .foregroundStyle(isOn ? Color.accentColor : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var findingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.tint)
                Text("F3 · 발견 (Finding) — 이 한 줄만 노트에 남아요")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
            }
            TextField(
                "예: 스타일 주입은 modifier가 아니라 value. EnvironmentValues가 맞다.",
                text: $finding,
                axis: .vertical
            )
            .lineLimit(3...6)
            .padding(12)
            .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.tint, lineWidth: 1)
            )
        }
    }

    private var submitButton: some View {
        Button {
            commit()
            dismiss()
        } label: {
            Text("회고 완료 · 내일 준비")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(finding.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func section<Content: View>(
        label: String,
        hint: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let hint {
                    Text("— \(hint)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            content()
        }
    }

    private func hydrate() {
        fact = entry.fact ?? ""
        feelingTags = Set(entry.feeling)
        finding = entry.finding ?? ""
        futureAction = entry.futureAction ?? ""
    }

    private func commit() {
        let trimmedFinding = finding.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFinding.isEmpty else { return }

        entry.fact = trimAndNilIfEmpty(fact)
        entry.feeling = Array(feelingTags)
        entry.finding = trimmedFinding
        entry.futureAction = trimAndNilIfEmpty(futureAction)
        entry.completedAt = .now

        // Promote Finding to Notebook.
        let promoted = Finding(
            text: trimmedFinding,
            tags: entry.project.map { [$0] } ?? [],
            sourceDate: entry.date,
            sourceEntry: entry
        )
        context.insert(promoted)

        try? context.save()
    }

    private func trimAndNilIfEmpty(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

// MARK: - FlowLayout

/// Minimal flow layout for chip rows. iOS 16+.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
