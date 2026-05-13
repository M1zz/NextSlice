import SwiftUI
import SwiftData

/// The calm mid-day state. Shows today's intent in large type. Optional mid-notes.
struct DayActiveView: View {
    @Environment(\.modelContext) private var context
    @Bindable var entry: DailyEntry

    @State private var newNote = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                Text(entry.intent)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                Divider()

                midNotesSection
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 한 가지")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if let project = entry.project {
                Label(project, systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
    }

    private var midNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("메모")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(entry.midNotes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(entry.midNotes.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(.secondary)
                        .padding(.top, 7)
                    Text(entry.midNotes[idx])
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                TextField("짧은 메모…", text: $newNote)
                    .textFieldStyle(.roundedBorder)
                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entry.midNotes.append(trimmed)
        newNote = ""
        try? context.save()
    }
}
