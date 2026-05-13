import SwiftUI
import SwiftData

/// Sunday weekly retrospective. The one place where past Findings come back.
struct WeekView: View {
    @Environment(\.modelContext) private var context
    @Query private var stages: [UserStage]
    @Query(sort: \Finding.sourceDate, order: .reverse) private var findings: [Finding]

    @State private var recalledFinding: Finding?
    @State private var recallResponse: String = ""
    @State private var patternText: String = ""
    @State private var currentWeekPattern: WeeklyPattern?

    private var stage: UserStage { stages.first ?? UserStage() }

    private var weekStart: Date { Date.now.weekStart() }

    private var thisWeekFindings: [Finding] {
        findings.filter { $0.sourceDate >= weekStart }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    TrustGaugeView(stage: stage)
                    thisWeekSection
                    if let recall = recalledFinding {
                        recallSection(recall)
                    }
                    patternSection
                    actionRow
                }
                .padding(20)
            }
            .navigationTitle("주간")
            .navigationBarTitleDisplayMode(.large)
            .task { await prepare() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("일요일 · 주간 회고")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("이번 주의 Finding")
                .font(.title2.weight(.medium))
        }
    }

    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이번 주 · Finding \(thisWeekFindings.count)개")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if thisWeekFindings.isEmpty {
                Text("이번 주 Finding이 아직 없어요. 오늘 회고를 완료하면 주간 회고가 채워져요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(thisWeekFindings) { f in
                    miniRow(f)
                }
            }
        }
    }

    private func miniRow(_ f: Finding) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(.secondary.opacity(0.4))
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(f.sourceDate, format: .dateTime.weekday(.short).month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(f.text)
                    .font(.callout)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    private func recallSection(_ finding: Finding) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "지난 기록 · \(finding.ageInDays)일 전",
                systemImage: "arrow.uturn.backward"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 12) {
                Text(finding.sourceDate.formatted(date: .long, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\u{201C}\(finding.text)\u{201D}")
                    .font(.callout.weight(.medium))

                Text("지금도 유효한가요? 한 줄로 답해보세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("예/아니오/달라졌다 — 그리고 그 이유.", text: $recallResponse, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(14)
            .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.tint.opacity(0.4))
            )
        }
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("한 줄로 — 어떤 패턴이 보이나요?")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(
                "예: 추상화 관련 finding이 반복된다. 다음 주엔 3번 복붙 후에 추상화하기.",
                text: $patternText,
                axis: .vertical
            )
            .lineLimit(3...5)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.secondary.opacity(0.3))
            )
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                exportCard()
            } label: {
                Label("카드 내보내기", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                commit()
            } label: {
                Text("주간 마감")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .disabled(patternText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.top, 8)
    }

    // MARK: - Behavior

    @MainActor
    private func prepare() async {
        // Load or create this week's pattern row
        let ws = weekStart
        let next = Calendar.current.date(byAdding: .day, value: 7, to: ws) ?? ws

        var desc = FetchDescriptor<WeeklyPattern>(
            predicate: #Predicate { p in
                p.weekStart >= ws && p.weekStart < next
            }
        )
        desc.fetchLimit = 1

        if let existing = try? context.fetch(desc).first {
            currentWeekPattern = existing
            patternText = existing.pattern
            recallResponse = existing.recallResponse ?? ""
        }

        // Pick recall finding
        let recallSvc = ReflectionRecallService(context: context)
        recalledFinding = recallSvc.pickRecalledFinding(weekStart: ws)
    }

    private func commit() {
        let trimmed = patternText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let pattern: WeeklyPattern
        if let existing = currentWeekPattern {
            pattern = existing
        } else {
            pattern = WeeklyPattern(weekStart: weekStart)
            context.insert(pattern)
        }

        pattern.pattern = trimmed
        pattern.recallResponse = recallResponse.isEmpty ? nil : recallResponse
        pattern.recalledFindingText = recalledFinding?.text
        pattern.recalledFindingSourceDate = recalledFinding?.sourceDate
        pattern.completedAt = .now

        // Mark the recalled Finding as reviewed.
        if let recalled = recalledFinding {
            recalled.lastReviewedAt = .now
        }

        try? context.save()
    }

    private func exportCard() {
        // TODO: Render WeeklyPattern + Findings as a shareable card image (Look-and-Say format).
        // Hook into ShareLink with a rendered UIImage or PDF.
    }
}
