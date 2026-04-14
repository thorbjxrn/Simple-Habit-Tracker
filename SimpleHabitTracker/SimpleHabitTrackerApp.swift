import SwiftUI
import SwiftData

@main
struct SimpleHabitTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Habit.self)
            let context = ModelContext(modelContainer)
            MigrationManager.migrateIfNeeded(context: context)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HabitTrackerView()
        }
        .modelContainer(modelContainer)
    }
}
