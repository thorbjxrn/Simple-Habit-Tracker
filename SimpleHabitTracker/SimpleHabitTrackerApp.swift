import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SimpleHabitTrackerApp: App {
    let modelContainer: ModelContainer
    @State private var purchaseManager = PurchaseManager()
    @State private var adManager: AdManager?

    init() {
        do {
            modelContainer = try ModelContainer(for: Habit.self)
            let context = ModelContext(modelContainer)
            MigrationManager.migrateIfNeeded(context: context)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            HabitTrackerView()
                .environment(purchaseManager)
                .task {
                    if adManager == nil {
                        adManager = AdManager(purchaseManager: purchaseManager)
                    }
                }
                .environment(adManager)
        }
        .modelContainer(modelContainer)
    }
}
