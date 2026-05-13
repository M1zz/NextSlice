import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var stages: [UserStage]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("오늘", systemImage: timeIcon) }

            NotebookView()
                .tabItem { Label("노트", systemImage: "book.closed") }

            WeekView()
                .tabItem { Label("주간", systemImage: "calendar.badge.clock") }
        }
        .task { await ensureStage() }
    }

    private var timeIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 18 ? "sun.max" : "moon.stars"
    }

    @MainActor
    private func ensureStage() async {
        guard stages.isEmpty else { return }
        context.insert(UserStage())
        try? context.save()
    }
}
