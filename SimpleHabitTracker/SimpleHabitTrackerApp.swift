import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SimpleHabitTrackerApp: App {
    let modelContainer: ModelContainer
    @State private var purchaseManager: PurchaseManager
    @State private var adManager: AdManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    init() {
        let pm = PurchaseManager()
        _purchaseManager = State(initialValue: pm)
        _adManager = State(initialValue: AdManager(purchaseManager: pm))

        let syncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        let isPremiumCached = UserDefaults.standard.bool(forKey: "isPremiumCached")

        do {
            let config: ModelConfiguration
            if syncEnabled && isPremiumCached {
                config = ModelConfiguration(
                    cloudKitDatabase: .private("iCloud.thorbjxrn.SimpleHabitTracker")
                )
            } else {
                config = ModelConfiguration(cloudKitDatabase: .none)
            }
            modelContainer = try ModelContainer(for: Habit.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            HabitTrackerView()
                .environment(purchaseManager)
                .environment(adManager)
                .onAppear {
                    if !hasCompletedOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
