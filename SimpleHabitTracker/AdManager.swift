import Foundation
import GoogleMobileAds
import UIKit

@Observable
@MainActor
final class AdManager {
    // MARK: - Ad Unit IDs

    #if DEBUG
    private static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private static let interstitialAdUnitID = "ca-app-pub-3919813110479769/6042194583"
    #endif

    // MARK: - State

    private(set) var interstitialAd: InterstitialAd?

    /// True once the Mobile Ads SDK has started. No ad may be requested before this.
    private(set) var adsStarted = false

    @ObservationIgnored
    private static let appOpenCountKey = "adManager_appOpenCount"

    /// Number of app opens before any ads appear (banner or interstitial)
    private static let gracePeriodOpens = 5
    /// Show an interstitial every Nth history navigation after the grace period
    private static let interstitialFrequency = 5

    @ObservationIgnored
    private static let historyNavCountKey = "adManager_historyNavCount"

    var appOpenCount: Int {
        didSet {
            UserDefaults.standard.set(appOpenCount, forKey: Self.appOpenCountKey)
        }
    }

    private(set) var historyNavCount: Int {
        didSet {
            UserDefaults.standard.set(historyNavCount, forKey: Self.historyNavCountKey)
        }
    }

    /// Whether we're still in the ad-free grace period
    var isInGracePeriod: Bool {
        appOpenCount <= Self.gracePeriodOpens
    }

    /// Whether to show the banner ad (hidden during grace period)
    var shouldShowBanner: Bool {
        adsStarted && !purchaseManager.isPremium && !isInGracePeriod
    }

    /// Call when the user navigates to a past week. Returns true if an interstitial should show.
    func onHistoryNavigation() -> Bool {
        guard !purchaseManager.isPremium else { return false }
        guard !isInGracePeriod else { return false }
        historyNavCount += 1
        return historyNavCount % Self.interstitialFrequency == 0
    }

    // MARK: - Dependencies

    @ObservationIgnored
    let purchaseManager: PurchaseManager

    // MARK: - Init

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager

        self.historyNavCount = UserDefaults.standard.integer(forKey: Self.historyNavCountKey)
        self.appOpenCount = UserDefaults.standard.integer(forKey: Self.appOpenCountKey)
        self.appOpenCount += 1
    }

    // MARK: - Startup (SDK)

    /// Starts the Mobile Ads SDK and preloads the first interstitial (never for
    /// premium or grace-period users). Called once from the app root.
    /// No ATT prompt: every request is explicitly non-personalized (npa=1).
    func startAdsIfNeeded() async {
        guard !adsStarted else { return }
        guard !purchaseManager.isPremium, !isInGracePeriod else { return }

        await MobileAds.shared.start()
        adsStarted = true
        loadInterstitial()
    }

    /// All ad requests in the app must go through this: non-personalized only.
    static func nonPersonalizedRequest() -> AdManagerRequest {
        let request = AdManagerRequest()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }

    // MARK: - Interstitial Ad Loading

    func loadInterstitial() {
        guard !purchaseManager.isPremium else { return }

        Task { @MainActor in
            do {
                interstitialAd = try await InterstitialAd.load(
                    with: Self.interstitialAdUnitID,
                    request: Self.nonPersonalizedRequest()
                )
            } catch {
                print("AdManager: Failed to load interstitial: \(error.localizedDescription)")
                interstitialAd = nil
            }
        }
    }

    // MARK: - Show Interstitial

    func showInterstitial(from rootViewController: UIViewController) {
        guard !purchaseManager.isPremium else { return }

        guard let ad = interstitialAd else {
            print("AdManager: Interstitial not ready")
            loadInterstitial()
            return
        }

        ad.present(from: rootViewController)
        interstitialAd = nil
        loadInterstitial()
    }

    /// Convenience: find the root view controller and show interstitial
    func showInterstitialIfReady() {
        guard interstitialAd != nil else { return }
        guard !purchaseManager.isPremium else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // Walk to the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        showInterstitial(from: topVC)
    }
}
