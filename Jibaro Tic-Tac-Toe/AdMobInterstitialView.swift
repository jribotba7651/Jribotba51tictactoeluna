import SwiftUI
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var isLoading = false
    @Published var isReady = false

    private var interstitialAd: GADInterstitialAd?
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // Test Interstitial ID
    private let purchaseManager = PurchaseManager.shared
    private let gameFrequency = 10 // Mostrar anuncio cada 10 juegos

    override init() {
        super.init()
        loadInterstitialAd()
    }

    func loadInterstitialAd() {
        // No cargar anuncios si el usuario los removió
        if purchaseManager.hasRemovedAds {
            print("🚫 Ads removed by purchase - not loading interstitial")
            return
        }

        isLoading = true
        isReady = false

        let request = GADRequest()

        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }

                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isReady = true
                print("✅ Interstitial ad loaded successfully")
            }
        }
    }

    func presentInterstitialAd() {
        // No mostrar anuncios si el usuario los removió
        if purchaseManager.hasRemovedAds {
            print("🚫 Ads removed by purchase - not showing interstitial")
            return
        }

        guard let interstitialAd = interstitialAd else {
            print("❌ Interstitial ad not ready")
            loadInterstitialAd() // Try to load again
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }

        interstitialAd.present(fromRootViewController: rootViewController)
        print("🎬 Presenting interstitial ad")
    }

    func shouldShowAdAfterGames(_ gamesCount: Int) -> Bool {
        return !purchaseManager.hasRemovedAds && gamesCount % gameFrequency == 0
    }

    // MARK: - GADFullScreenContentDelegate

    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("🎯 Interstitial ad recorded impression")
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWith error: Error) {
        print("❌ Interstitial ad failed to present: \(error.localizedDescription)")
        loadInterstitialAd() // Try to load a new ad
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("🎬 Interstitial ad will present")
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("👋 Interstitial ad dismissed")
        loadInterstitialAd() // Load a new ad for next time
    }
}