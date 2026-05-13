import SwiftUI
import SwiftData

/// Edit a goal: title, color, archive. When `isNew` is true the goal is
/// inserted into the context only on save (otherwise mutations are tracked live).
struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal
    var isNew: Bool = false

    private static let palette: [String] = [
        "4FACFE", "FF6B9D", "FFC542", "5DD39E",
        "8B5CF6", "F87171", "38BDF8", "A78BFA"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("목표") {
                    TextField("예: SwiftUI 컴포넌트 시스템 익히기", text: $goal.title)
                }

                Section("색상") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8),
                             spacing: 12) {
                        ForEach(Self.palette, id: \.self) { hex in
                            colorSwatch(hex)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            archive()
                        } label: {
                            Label("보관함으로 이동", systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Label("완전히 삭제", systemImage: "trash")
                        }
                    } footer: {
                        Text("보관함으로 이동하면 타임라인에서 사라지지만 데이터는 남아요.")
                    }
                }
            }
            .navigationTitle(isNew ? "새 목표" : "목표 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "추가" : "완료") { save() }
                        .disabled(goal.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func colorSwatch(_ hex: String) -> some View {
        let color = Color(hex: hex) ?? .accentColor
        let isSelected = goal.colorHex == hex
        return Button {
            goal.colorHex = hex
        } label: {
            ZStack {
                Circle().fill(color).frame(width: 30, height: 30)
                if isSelected {
                    Circle()
                        .strokeBorder(.primary, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        if isNew { context.insert(goal) }
        try? context.save()
        dismiss()
    }

    private func cancel() {
        if isNew {
            // The draft is detached; do not insert.
        } else {
            context.rollback()
        }
        dismiss()
    }

    private func archive() {
        goal.archivedAt = .now
        try? context.save()
        dismiss()
    }

    private func delete() {
        context.delete(goal)
        try? context.save()
        dismiss()
    }
}

/// Edit or create a milestone. Pass `milestone: nil` + `presetGoal` to create.
struct MilestoneEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let milestone: Milestone?
    let presetGoal: Goal?

    @State private var title: String = ""
    @State private var date: Date = .now
    @State private var isDone: Bool = false

    init(milestone: Milestone?, presetGoal: Goal? = nil) {
        self.milestone = milestone
        self.presetGoal = presetGoal
        _title = State(initialValue: milestone?.title ?? "")
        _date = State(initialValue: milestone?.date ?? .now)
        _isDone = State(initialValue: milestone?.isDone ?? false)
    }

    private var isNew: Bool { milestone == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("마일스톤") {
                    TextField("예: 1차 프로토타입", text: $title)
                    DatePicker("날짜", selection: $date, displayedComponents: .date)
                }

                Section {
                    Toggle("완료", isOn: $isDone)
                }

                if let ms = milestone {
                    Section {
                        Button(role: .destructive) {
                            context.delete(ms)
                            try? context.save()
                            dismiss()
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "새 마일스톤" : "마일스톤 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "추가" : "완료") { commit() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func commit() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let ms = milestone {
            ms.title = trimmed
            ms.date = date
            ms.doneAt = isDone ? (ms.doneAt ?? .now) : nil
        } else if let goal = presetGoal {
            let new = Milestone(
                title: trimmed,
                date: date,
                goal: goal,
                doneAt: isDone ? .now : nil
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
