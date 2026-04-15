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

        do {
            modelContainer = try ModelContainer(for: Habit.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        #if !DEBUG
        #error("Replace GADApplicationIdentifier in Info.plist with real AdMob App ID, then remove this error")
        #endif
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
