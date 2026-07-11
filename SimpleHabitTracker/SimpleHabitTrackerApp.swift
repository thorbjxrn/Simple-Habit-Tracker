import SwiftUI
import SwiftData
import GoogleMobileAds
import TipKit
import WidgetKit

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

        SharedModelContainer.migrateStoreToAppGroupIfNeeded()

        // Sync settings to shared UserDefaults for widget access
        let shared = SharedModelContainer.sharedUserDefaults
        shared.set(UserDefaults.standard.bool(forKey: "isPremiumCached"), forKey: "isPremiumCached")
        shared.set(UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.defaultTheme.rawValue, forKey: "selectedTheme")

        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            // Never crash-loop on a CloudKit store failure — fall back to the
            // local store (same URL, sync disabled) and keep the user's data usable.
            print("CloudKit container failed, falling back to local store: \(error)")
            do {
                modelContainer = try SharedModelContainer.create(forWidget: true)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

        MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
        // MobileAds.shared.start() is deferred to AdManager.startAdsIfNeeded(),
        // which resolves App Tracking Transparency before any ad request.

        try? Tips.configure()
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
                .task {
                    await adManager.startAdsIfNeeded()
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    WidgetReloader.requestReload()
                }
        }
        .modelContainer(modelContainer)
    }
}
