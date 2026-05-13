import SwiftUI
import SwiftData

/// Horizontal milestone timeline. One lane per active goal, dots placed by date.
/// "Today" is a vertical marker and the scroll view centers on it on appear.
struct GoalTimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Goal> { $0.archivedAt == nil },
           sort: \Goal.createdAt, order: .forward)
    private var goals: [Goal]

    @State private var editingGoal: Goal?
    @State private var showWizard: Bool = false
    @State private var editingMilestone: Milestone?
    @State private var addMilestoneForGoal: Goal?

    private let pointsPerDay: CGFloat = 28
    private let laneHeight: CGFloat = 44
    private let monthHeaderHeight: CGFloat = 28
    private let basePaddingDays: Int = 90

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if goals.isEmpty {
                emptyState
            } else {
                legend
                timelineScroller
            }
        }
        .sheet(item: $editingGoal) { goal in
            GoalEditorView(goal: goal)
        }
        .sheet(isPresented: $showWizard) {
            GoalCreationWizardView()
        }
        .sheet(item: $editingMilestone) { ms in
            MilestoneEditorView(milestone: ms)
        }
        .sheet(item: $addMilestoneForGoal) { goal in
            MilestoneEditorView(milestone: nil, presetGoal: goal)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Label("목표 타임라인", systemImage: "flag.checkered")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if !goals.isEmpty {
                Button {
                    showWizard = true
                } label: {
                    Label("목표 추가", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
    }

    private var emptyState: some View {
        Button {
            showWizard = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.tint)
                Text("첫 목표 만들기")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("큰 목표 하나와 작은 첫 발걸음을 함께 정해요.\n3단계면 끝나요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.accentColor.opacity(0.3),
                                  style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend (goal titles + color swatches)

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(goals) { goal in
                Button {
                    editingGoal = goal
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(goal.swiftUIColor)
                            .frame(width: 10, height: 10)
                        Text(goal.title.isEmpty ? "(제목 없음)" : goal.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        Text("\(goal.milestones.count)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            addMilestoneForGoal = goal
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Timeline scroller

    private var timelineRange: (start: Date, dayCount: Int) {
        let today = Date.now.dayStart
        let cal = Calendar.current
        var minDay = -basePaddingDays
        var maxDay = basePaddingDays
        for goal in goals {
            for ms in goal.milestones {
                let d = cal.dateComponents([.day], from: today, to: ms.date.dayStart).day ?? 0
                minDay = min(minDay, d - 14)
                maxDay = max(maxDay, d + 14)
            }
        }
        let start = cal.date(byAdding: .day, value: minDay, to: today) ?? today
        return (start, maxDay - minDay + 1)
    }

    private func xOffset(for date: Date, rangeStart: Date) -> CGFloat {
        let days = Calendar.current.dateComponents([.day], from: rangeStart, to: date.dayStart).day ?? 0
        return CGFloat(days) * pointsPerDay + pointsPerDay / 2
    }

    private var timelineScroller: some View {
        let range = timelineRange
        let totalWidth = CGFloat(range.dayCount) * pointsPerDay
        let totalHeight = monthHeaderHeight + CGFloat(goals.count) * laneHeight + 8

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    monthHeader(rangeStart: range.start, dayCount: range.dayCount)

                    todayMarker(rangeStart: range.start, totalHeight: totalHeight)

                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: monthHeaderHeight)
                        ForEach(Array(goals.enumerated()), id: \.element.id) { _, goal in
                            goalLane(goal, rangeStart: range.start, width: totalWidth)
                                .frame(height: laneHeight)
                        }
                    }
                }
                .frame(width: totalWidth, height: totalHeight, alignment: .topLeading)
                .padding(.vertical, 4)
            }
            .frame(height: totalHeight + 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.none) {
                        proxy.scrollTo("today-anchor", anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Month header

    private func monthHeader(rangeStart: Date, dayCount: Int) -> some View {
        let cal = Calendar.current
        let monthBoundaries: [(date: Date, offsetDays: Int)] = {
            var result: [(Date, Int)] = []
            var cursor = cal.date(
                from: cal.dateComponents([.year, .month], from: rangeStart)
            ) ?? rangeStart
            while cursor < cal.date(byAdding: .day, value: dayCount, to: rangeStart) ?? rangeStart {
                let off = cal.dateComponents([.day], from: rangeStart, to: cursor).day ?? 0
                result.append((cursor, off))
                cursor = cal.date(byAdding: .month, value: 1, to: cursor) ?? cursor
            }
            return result
        }()

        return ZStack(alignment: .topLeading) {
            ForEach(monthBoundaries, id: \.offsetDays) { boundary in
                VStack(alignment: .leading, spacing: 2) {
                    Text(boundary.date, format: .dateTime.year(.twoDigits).month(.abbreviated))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(.secondary.opacity(0.15))
                        .frame(width: 1, height: 8)
                }
                .offset(x: max(0, CGFloat(boundary.offsetDays) * pointsPerDay), y: 4)
            }
        }
        .frame(height: monthHeaderHeight, alignment: .topLeading)
    }

    // MARK: - Today marker

    private func todayMarker(rangeStart: Date, totalHeight: CGFloat) -> some View {
        let today = Date.now.dayStart
        let x = xOffset(for: today, rangeStart: rangeStart)
        return Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2, height: totalHeight - monthHeaderHeight + 12)
            .offset(x: x - 1, y: monthHeaderHeight - 6)
            .id("today-anchor")
            .accessibilityLabel("오늘")
    }

    // MARK: - Goal lane

    private func goalLane(_ goal: Goal, rangeStart: Date, width: CGFloat) -> some View {
        let today = Date.now.dayStart
        return ZStack(alignment: .leading) {
            // Lane baseline
            Rectangle()
                .fill(goal.swiftUIColor.opacity(0.25))
                .frame(width: width, height: 2)

            ForEach(goal.milestones) { ms in
                milestoneDot(ms, goalColor: goal.swiftUIColor, today: today)
                    .offset(x: xOffset(for: ms.date, rangeStart: rangeStart) - 9)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func milestoneDot(_ ms: Milestone, goalColor: Color, today: Date) -> some View {
        let isPast = ms.date.dayStart < today
        let isToday = Calendar.current.isDate(ms.date, inSameDayAs: today)

        Button {
            editingMilestone = ms
        } label: {
            ZStack {
                Circle()
                    .fill(ms.isDone ? goalColor : Color(.systemBackground))
                    .frame(width: isToday ? 22 : 18, height: isToday ? 22 : 18)
                Circle()
                    .strokeBorder(goalColor, lineWidth: 2)
                    .frame(width: isToday ? 22 : 18, height: isToday ? 22 : 18)
                if ms.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .opacity(isPast && !ms.isDone ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ms.title), \(ms.date.formatted(date: .abbreviated, time: .omitted))")
    }
}

// MARK: - Color helpers

extension Goal {
    var swiftUIColor: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
