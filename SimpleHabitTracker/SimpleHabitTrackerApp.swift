import SwiftUI
import SwiftData

@main
struct SimpleHabitTrackerApp: App {
    let modelContainer: ModelContainer
    @State private var purchaseManager = PurchaseManager()

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
                .environment(purchaseManager)
        }
        .modelContainer(modelContainer)
    }
}
