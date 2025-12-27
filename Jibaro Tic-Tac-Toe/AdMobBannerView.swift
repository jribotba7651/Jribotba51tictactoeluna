import SwiftUI
import GoogleMobileAds
import UIKit

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    @ObservedObject private var purchaseManager = PurchaseManager.shared

    func makeUIView(context: Context) -> UIView {
        // Si el usuario compró la remoción de anuncios, mostrar vista vacía
        if purchaseManager.hasRemovedAds {
            let emptyView = UIView()
            emptyView.backgroundColor = UIColor.clear
            return emptyView
        }

        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = getRootViewController()

        let request = GADRequest()
        bannerView.load(request)

        print("🎯 AdMob Banner loading with ID: \(adUnitID)")

        return bannerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Si el estado de compra cambió, recrear la vista
        if purchaseManager.hasRemovedAds && uiView is GADBannerView {
            // Reemplazar con vista vacía
            if let containerView = uiView.superview {
                let emptyView = UIView()
                emptyView.backgroundColor = UIColor.clear
                emptyView.frame = uiView.frame
                containerView.addSubview(emptyView)
                uiView.removeFromSuperview()
            }
        }
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// Extension para obtener el root view controller de manera más robusta
extension UIApplication {
    var currentUIWindow: UIWindow? {
        connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .map({ $0?.windows.first })
            ?? nil
    }
}

struct AdMobBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AdMobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716") // Test Ad Unit ID
            .frame(height: 50)
    }
}

// MARK: - Test Ad Unit IDs
extension AdMobBannerView {
    static let testBannerID = "ca-app-pub-3940256099942544/2934735716"
    static let productionBannerID = "ca-app-pub-3258994800717071/5955178067"
}