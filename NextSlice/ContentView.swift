import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var stages: [UserStage]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: timeIcon) }

            NotebookView()
                .tabItem { Label("Notebook", systemImage: "book.closed") }

            WeekView()
                .tabItem { Label("Week", systemImage: "calendar.badge.clock") }
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
