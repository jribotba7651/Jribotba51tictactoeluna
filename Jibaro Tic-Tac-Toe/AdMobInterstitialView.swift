import SwiftUI
// import GoogleMobileAds // Descomentar después de agregar la dependencia
import UIKit

class InterstitialAdManager: NSObject, ObservableObject {
    @Published var isLoading = false

    private let adUnitID = "ca-app-pub-3258994800717071/8816859712"

    override init() {
        super.init()
        loadInterstitialAd()
    }

    func loadInterstitialAd() {
        isLoading = true
        print("🔄 Loading interstitial ad (placeholder): \(adUnitID)")

        // Simular carga de anuncio
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            print("✅ Interstitial ad loaded (placeholder)")
        }
    }

    func presentInterstitialAd() {
        print("🎬 Would show interstitial ad here: \(adUnitID)")

        // Placeholder: mostrar una alerta
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }

        let alert = UIAlertController(
            title: "Anuncio Intersticial",
            message: "Aquí aparecería un anuncio de AdMob\nID: \(adUnitID)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cerrar", style: .default))

        rootViewController.present(alert, animated: true) {
            // Simular recarga del anuncio
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadInterstitialAd()
            }
        }
    }
}