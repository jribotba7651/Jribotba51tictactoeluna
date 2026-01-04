import SwiftUI
import UIKit
import GoogleMobileAds
import StoreKit

// PurchaseManager para In-App Purchases
class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()

    @Published var hasRemovedAds = false
    @Published var isLoading = false

    private let removeAdsProductID = "com.jibaroenlaluna.tictactoe.removeads"
    private var products: [SKProduct] = []

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadPurchaseStatus()
        requestProducts()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    private func loadPurchaseStatus() {
        hasRemovedAds = UserDefaults.standard.bool(forKey: "hasRemovedAds")
        print("📱 Purchase status loaded: hasRemovedAds = \(hasRemovedAds)")
    }

    private func savePurchaseStatus() {
        UserDefaults.standard.set(hasRemovedAds, forKey: "hasRemovedAds")
        print("💾 Purchase status saved: hasRemovedAds = \(hasRemovedAds)")
    }

    func requestProducts() {
        let request = SKProductsRequest(productIdentifiers: Set([removeAdsProductID]))
        request.delegate = self
        request.start()
    }

    func purchaseRemoveAds() {
        guard let product = products.first(where: { $0.productIdentifier == removeAdsProductID }) else {
            print("❌ Product not found: \(removeAdsProductID)")
            return
        }

        guard SKPaymentQueue.canMakePayments() else {
            print("❌ Cannot make payments")
            return
        }

        isLoading = true
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("🛒 Initiating purchase for: \(removeAdsProductID)")
    }

    func restorePurchases() {
        isLoading = true
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("🔄 Restoring purchases...")
    }

    func getRemoveAdsProduct() -> SKProduct? {
        return products.first(where: { $0.productIdentifier == removeAdsProductID })
    }
}

// MARK: - SKProductsRequestDelegate
extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            print("✅ Products loaded: \(response.products.map { $0.productIdentifier })")

            if response.invalidProductIdentifiers.count > 0 {
                print("⚠️ Invalid product identifiers: \(response.invalidProductIdentifiers)")
            }
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("✅ Purchase successful: \(transaction.payment.productIdentifier)")
                completePurchase(transaction)
            case .failed:
                let errorMessage = transaction.error?.localizedDescription ?? "Unknown error"
                print("❌ Purchase failed: \(errorMessage)")
                SKPaymentQueue.default().finishTransaction(transaction)
                DispatchQueue.main.async {
                    self.isLoading = false
                    NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMessage)
                }
            case .restored:
                print("🔄 Purchase restored: \(transaction.payment.productIdentifier)")
                completePurchase(transaction)
            case .deferred:
                print("⏳ Purchase deferred")
            case .purchasing:
                print("🛒 Purchasing...")
            @unknown default:
                break
            }
        }
    }

    private func completePurchase(_ transaction: SKPaymentTransaction) {
        if transaction.payment.productIdentifier == removeAdsProductID {
            DispatchQueue.main.async {
                self.hasRemovedAds = true
                self.savePurchaseStatus()
                self.isLoading = false
                NotificationCenter.default.post(name: .init("PurchaseCompleted"), object: nil)
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

// Extension para SKProduct para obtener precio formateado
extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}

// InterstitialAdManager para anuncios intersticiales
class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var isLoading = false
    @Published var isReady = false

    private var interstitialAd: InterstitialAd?
    private let adUnitID = "ca-app-pub-3258994800717071/8816859712" // Production Interstitial ID
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

        let request = Request()

        InterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
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

    // MARK: - FullScreenContentDelegate

    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("🎯 Interstitial ad recorded impression")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Interstitial ad failed to present: \(error.localizedDescription)")
        loadInterstitialAd() // Try to load a new ad
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 Interstitial ad will present")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("👋 Interstitial ad dismissed")
        loadInterstitialAd() // Load a new ad for next time
    }
}

// AdMobBannerView para anuncios banner
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

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = getRootViewController()

        let request = Request()
        bannerView.load(request)

        print("🎯 AdMob Banner loading with ID: \(adUnitID)")

        return bannerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Si el estado de compra cambió, recrear la vista
        if purchaseManager.hasRemovedAds && uiView is BannerView {
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

// AppDelegate para inicializar AdMob
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Inicializar Google Mobile Ads SDK
        MobileAds.sharedInstance().start(completionHandler: { status in
            print("🎯 Google Mobile Ads SDK initialized successfully")
            print("🎯 AdMob adapters status: \(status)")
        })

        print("🍃 AppDelegate initialized successfully")
        return true
    }
}

@main
struct Jibaro_Tic_Tac_ToeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}