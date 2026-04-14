import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import UIKit

@Observable
@MainActor
final class AdManager {
    // MARK: - Ad Unit IDs

    #if DEBUG
    private static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Replace with real ID before release
    #endif

    // MARK: - State

    private(set) var interstitialAd: InterstitialAd?

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
        !purchaseManager.isPremium && !isInGracePeriod
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

        if !isInGracePeriod {
            loadInterstitial()
        }
    }

    // MARK: - ATT Permission

    func requestTrackingPermissionIfNeeded() {
        // Request ATT just before ads start appearing
        guard appOpenCount == Self.gracePeriodOpens else { return }

        Task { @MainActor in
            // Small delay to let the UI settle
            try? await Task.sleep(for: .seconds(1))

            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                await ATTrackingManager.requestTrackingAuthorization()
            }
        }
    }

    // MARK: - Interstitial Ad Loading

    func loadInterstitial() {
        guard !purchaseManager.isPremium else { return }

        Task { @MainActor in
            do {
                interstitialAd = try await InterstitialAd.load(
                    with: Self.interstitialAdUnitID,
                    request: AdManagerRequest()
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
