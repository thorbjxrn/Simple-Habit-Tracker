import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174" // Replace with real ID before release
    #endif

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = adUnitID

        // Get the window scene for adaptive banner sizing
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let viewWidth = windowScene.windows.first?.frame.width ?? UIScreen.main.bounds.width
            bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)

            bannerView.rootViewController = windowScene.windows.first?.rootViewController
        }

        bannerView.load(GAMRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // No updates needed
    }
}
