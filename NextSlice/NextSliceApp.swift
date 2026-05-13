import SwiftUI
import SwiftData

@main
struct NextSliceApp: App {

    // MARK: - Shared container
    //
    // The widget extension reads the same store. Use an App Group container
    // so both targets see the same database.
    //
    // TODO before first run:
    // 1. Add capability "App Groups" to both NextSlice and NextSliceWidget targets.
    // 2. Create group: `group.com.devkoan.NextSlice` (or any group you own).
    // 3. Update `AppGroup.identifier` below.
    let container: ModelContainer = {
        let schema = Schema([
            DailyEntry.self,
            Finding.self,
            WeeklyPattern.self,
            UserStage.self,
            Goal.self,
            Milestone.self,
        ])

        // Use App Group URL once the group is configured. Falls back to local
        // store while you're still wiring entitlements.
        let storeURL: URL = {
            if let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppGroup.identifier
            ) {
                return groupURL.appendingPathComponent("NextSlice.store")
            }
            let docs = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            )[0]
            return docs.appendingPathComponent("NextSlice.store")
        }()

        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

enum AppGroup {
    /// Replace with your team's App Group identifier.
    static let identifier = "group.com.devkoan.NextSlice"
}
