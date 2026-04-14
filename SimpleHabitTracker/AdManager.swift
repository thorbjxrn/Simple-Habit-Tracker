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
    private(set) var isFirstSession: Bool

    @ObservationIgnored
    private static let appOpenCountKey = "adManager_appOpenCount"
    @ObservationIgnored
    private static let hasLaunchedBeforeKey = "adManager_hasLaunchedBefore"

    var appOpenCount: Int {
        didSet {
            UserDefaults.standard.set(appOpenCount, forKey: Self.appOpenCountKey)
        }
    }

    var shouldShowInterstitial: Bool {
        guard !isFirstSession else { return false }
        guard !purchaseManager.isPremium else { return false }
        return appOpenCount > 0 && appOpenCount % 3 == 0
    }

    // MARK: - Dependencies

    @ObservationIgnored
    let purchaseManager: PurchaseManager

    // MARK: - Init

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager

        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: Self.hasLaunchedBeforeKey)
        self.isFirstSession = !hasLaunchedBefore

        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: Self.hasLaunchedBeforeKey)
        }

        self.appOpenCount = UserDefaults.standard.integer(forKey: Self.appOpenCountKey)
        self.appOpenCount += 1

        loadInterstitial()
    }

    // MARK: - ATT Permission

    func requestTrackingPermissionIfNeeded() {
        // Request on second session (not first)
        guard !isFirstSession else { return }
        guard appOpenCount == 2 else { return }

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
                    withAdUnitID: Self.interstitialAdUnitID,
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

        ad.present(fromRootViewController: rootViewController)
        interstitialAd = nil
        loadInterstitial()
    }

    /// Convenience: find the root view controller and show interstitial
    func showInterstitialIfReady() {
        guard shouldShowInterstitial || interstitialAd != nil else { return }
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
