import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SimpleHabitTrackerApp: App {
    let modelContainer: ModelContainer
    @State private var purchaseManager = PurchaseManager()
    @State private var adManager: AdManager?

    init() {
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        let isPremium = UserDefaults.standard.bool(forKey: "isPremiumCached")

        do {
            let config = ModelConfiguration(
                cloudKitDatabase: (isPremium && iCloudEnabled) ? .automatic : .none
            )
            modelContainer = try ModelContainer(for: Habit.self, configurations: config)
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
