import SwiftUI
import SwiftData

/// The long-term knowledge accumulator. Lives quietly — does not surface anything
/// proactively (active recall is delegated to the Weekly view).
struct NotebookView: View {
    @Query(sort: \Finding.sourceDate, order: .reverse) private var findings: [Finding]
    @State private var searchText = ""
    @State private var selectedTag: String?

    private var allTags: [String] {
        Array(Set(findings.flatMap(\.tags))).sorted()
    }

    private var filtered: [Finding] {
        findings.filter { f in
            let matchesTag = selectedTag.map { f.tags.contains($0) } ?? true
            let matchesQuery = searchText.isEmpty
                || f.text.localizedCaseInsensitiveContains(searchText)
                || f.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesTag && matchesQuery
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if findings.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("노트")
            .searchable(text: $searchText, prompt: "Finding 검색")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("여기에 Finding이 쌓여요.")
                .font(.headline)
            Text("오늘 회고를 완료하면 첫 Finding이 들어와요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var list: some View {
        List {
            if !allTags.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            tagChip("전체", isOn: selectedTag == nil) { selectedTag = nil }
                            ForEach(allTags, id: \.self) { tag in
                                tagChip(tag, isOn: selectedTag == tag) {
                                    selectedTag = selectedTag == tag ? nil : tag
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }

            Section {
                ForEach(filtered) { finding in
                    NavigationLink {
                        FindingDetailView(finding: finding)
                    } label: {
                        row(for: finding)
                    }
                }
            }
        }
    }

    private func row(for finding: Finding) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(finding.text)
                .font(.callout)
                .lineLimit(3)
            HStack(spacing: 8) {
                Text(finding.sourceDate, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if !finding.tags.isEmpty {
                    ForEach(finding.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.12), in: Capsule())
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func tagChip(_ text: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn ? Color.accentColor : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct FindingDetailView: View {
    let finding: Finding

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(finding.text)
                    .font(.title3.weight(.medium))

                HStack(spacing: 8) {
                    Label(
                        finding.sourceDate.formatted(date: .long, time: .omitted),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if finding.ageInDays > 0 {
                        Text("· \(finding.ageInDays)일 전")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !finding.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(finding.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.tint.opacity(0.12), in: Capsule())
                                .foregroundStyle(.tint)
                        }
                    }
                }

                if let entry = finding.sourceEntry {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("그날의 의도")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(entry.intent)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("발견")
        .navigationBarTitleDisplayMode(.inline)
    }
}
