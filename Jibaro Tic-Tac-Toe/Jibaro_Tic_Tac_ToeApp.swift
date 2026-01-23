import SwiftUI
import UIKit
import GoogleMobileAds
import StoreKit

// PurchaseManager para In-App Purchases
class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()

    @Published var hasRemovedAds = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let removeAdsProductID = "com.jibaroenlaluna.tictactoe.removeads"
    private var products: [SKProduct] = []

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadPurchaseStatus()
        requestProducts()
        DiagnosticsManager.shared.log("PurchaseManager initialized", type: .info)
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
        DiagnosticsManager.shared.log("Requesting products: \(removeAdsProductID)", type: .info)
    }

    func purchaseRemoveAds() {
        guard let product = products.first(where: { $0.productIdentifier == removeAdsProductID }) else {
            print("❌ Product not found: \(removeAdsProductID)")
            DiagnosticsManager.shared.log("Purchase failed: Product not found", type: .error)
            let errorMsg = "Los productos no están cargados. Por favor, intenta de nuevo en un momento."
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
                NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMsg)
            }
            // Intentar cargar productos de nuevo
            requestProducts()
            return
        }

        guard SKPaymentQueue.canMakePayments() else {
            print("❌ Cannot make payments")
            let errorMsg = "No se pueden realizar pagos. Verifica la configuración de tu dispositivo."
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
                NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMsg)
            }
            return
        }

        isLoading = true
        errorMessage = nil
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("🛒 Initiating purchase for: \(removeAdsProductID)")
        DiagnosticsManager.shared.log("Initiating purchase for: \(removeAdsProductID)", type: .info)
    }

    func restorePurchases() {
        isLoading = true
        errorMessage = nil
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("🔄 Restoring purchases...")
        
        // Si no hay transacciones para restaurar, el sistema no llamará a updatedTransactions
        // Necesitamos manejar esto con un timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isLoading && !self.hasRemovedAds {
                // Si después de 2 segundos aún está cargando y no se restauró nada, probablemente no hay compras
                self.isLoading = false
                let errorMsg = "No se encontraron compras para restaurar."
                self.errorMessage = errorMsg
                NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMsg)
            }
        }
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
            DiagnosticsManager.shared.log("Products loaded: \(response.products.count)", type: .success)
            DiagnosticsManager.shared.iapStatus = "Loaded (\(response.products.count))"

            if response.invalidProductIdentifiers.count > 0 {
                print("⚠️ Invalid product identifiers: \(response.invalidProductIdentifiers)")
                let errorMsg = "Algunos productos no son válidos. Por favor, contacta al soporte."
                self.errorMessage = errorMsg
                DiagnosticsManager.shared.log("Invalid Product IDs: \(response.invalidProductIdentifiers)", type: .warning)
                DiagnosticsManager.shared.iapStatus = "Invalid ID Found"
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Failed to load products: \(error.localizedDescription)")
            let errorMsg = "Error al cargar productos: \(error.localizedDescription)"
            self.errorMessage = errorMsg
            DiagnosticsManager.shared.log("Failed to load products: \(error.localizedDescription)", type: .error)
            DiagnosticsManager.shared.iapStatus = "Load Failed"
            NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMsg)
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
                DiagnosticsManager.shared.log("Purchase successful: \(transaction.payment.productIdentifier)", type: .success)
                completePurchase(transaction)
            case .failed:
                let errorMessage = transaction.error?.localizedDescription ?? "Unknown error"
                print("❌ Purchase failed: \(errorMessage)")
                DiagnosticsManager.shared.log("Purchase failed: \(errorMessage)", type: .error)
                SKPaymentQueue.default().finishTransaction(transaction)
                DispatchQueue.main.async {
                    self.isLoading = false
                    NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMessage)
                }
            case .restored:
                print("🔄 Purchase restored: \(transaction.payment.productIdentifier)")
                completePurchase(transaction)
                // Cancelar el timeout de restorePurchases si se restauró exitosamente
                DispatchQueue.main.async {
                    if self.isLoading {
                        self.isLoading = false
                    }
                }
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
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Restore purchases failed: \(error.localizedDescription)")
            DiagnosticsManager.shared.log("Restore failed: \(error.localizedDescription)", type: .error)
            self.isLoading = false
            let errorMsg = "Error al restaurar compras: \(error.localizedDescription)"
            self.errorMessage = errorMsg
            NotificationCenter.default.post(name: .init("PurchaseFailed"), object: errorMsg)
        }
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
    private let gameFrequency = 10
    private var retryAttempt = 0.0
    private let maxRetryDelay: TimeInterval = 64.0

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
        DiagnosticsManager.shared.log("Loading Interstitial Ad... (Retry: \(Int(retryAttempt)))", type: .info)

        let request = Request()

        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    DiagnosticsManager.shared.log("Interstitial load fail: \(error.localizedDescription)", type: .error)
                    self?.retryLoading()
                    return
                }

                self?.retryAttempt = 0
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isReady = true
                print("✅ Interstitial ad loaded successfully")
                DiagnosticsManager.shared.log("Interstitial ad loaded", type: .success)
            }
        }
    }
    
    private func retryLoading() {
        retryAttempt += 1
        let delay = min(pow(2.0, retryAttempt), maxRetryDelay)
        print("⏳ Retrying ad load in \(delay) seconds...")
        DiagnosticsManager.shared.log("Retrying ad load in \(Int(delay))s", type: .warning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.loadInterstitialAd()
        }
    }

    func presentInterstitialAd() {
        // No mostrar anuncios si el usuario los removió
        if purchaseManager.hasRemovedAds {
            print("🚫 Ads removed by purchase - not showing interstitial")
            return
        }

        // Verificar que el anuncio esté listo antes de presentarlo
        guard isReady, let interstitialAd = interstitialAd else {
            print("❌ Interstitial ad not ready (isReady: \(isReady), ad: \(interstitialAd != nil))")
            DiagnosticsManager.shared.log("Ad not ready when requested", type: .warning)
            loadInterstitialAd() // Trigger load immediately if not already loading
            return
        }

        // Usar el controlador superior para presentar
        guard let rootViewController = getRootViewController() else {
            print("❌ Could not find root view controller")
            DiagnosticsManager.shared.log("No RootVC found", type: .error)
            return
        }
        
        let topController = getTopViewController(base: rootViewController)
        interstitialAd.present(from: topController)
        print("🎬 Presenting interstitial ad from \(String(describing: type(of: topController)))")
        DiagnosticsManager.shared.log("Presenting Ad", type: .success)
    }

    private func getRootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }

    private func getTopViewController(base: UIViewController) -> UIViewController {
        if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
            return getTopViewController(base: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        }
        if let presented = base.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }

    func shouldShowAdAfterGames(_ gamesCount: Int) -> Bool {
        // Verificar que no se hayan removido los anuncios
        guard !purchaseManager.hasRemovedAds else {
            print("🚫 Ads removed - not showing interstitial")
            return false
        }
        
        // Verificar que el anuncio esté listo
        guard isReady else {
            print("⏳ Ad not ready yet - isReady: \(isReady)")
            return false
        }
        
        // Mostrar anuncio cuando el contador sea múltiplo de 10 (10, 20, 30, etc.)
        let shouldShow = gamesCount > 0 && gamesCount % gameFrequency == 0
        print("🎮 Should show ad? gamesCount: \(gamesCount), gameFrequency: \(gameFrequency), modulo: \(gamesCount % gameFrequency), shouldShow: \(shouldShow), isReady: \(isReady)")
        
        if shouldShow {
            print("✅ Conditions met for showing ad!")
        }
        
        return shouldShow
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
        bannerView.delegate = context.coordinator
        
        // Intentar obtener el root view controller inmediatamente
        if let rootVC = getRootViewController() {
            bannerView.rootViewController = rootVC
            print("✅ Banner rootViewController set immediately")
        } else {
            print("⚠️ Root View Controller not found initially, will retry")
            DiagnosticsManager.shared.log("Banner: RootVC missing initially", type: .warning)
            // Reintentar después de un breve delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let rootVC = self.getRootViewController() {
                    bannerView.rootViewController = rootVC
                    print("✅ Banner rootViewController set on retry")
                    // Recargar el banner después de configurar el rootViewController
                    bannerView.load(Request())
                }
            }
        }

        let request = Request()
        bannerView.load(request)

        print("🎯 AdMob Banner loading with ID: \(adUnitID)")
        DiagnosticsManager.shared.log("Banner loading: \(adUnitID)", type: .info)

        return bannerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let bannerView = uiView as? BannerView else { return }
        
        // Si el usuario compró la remoción de anuncios, no hacer nada (la vista se manejará en makeUIView)
        if purchaseManager.hasRemovedAds {
            return
        }
        
        // Asegurar que el rootViewController esté configurado - esto es crítico
        if bannerView.rootViewController == nil {
            if let rootVC = getRootViewController() {
                bannerView.rootViewController = rootVC
                print("✅ Banner rootViewController set in updateUIView")
                // Recargar el banner después de configurar el rootViewController
                bannerView.load(Request())
            } else {
                // Si aún no está disponible, intentar de nuevo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let rootVC = self.getRootViewController() {
                        bannerView.rootViewController = rootVC
                        bannerView.load(Request())
                        print("✅ Banner rootViewController set in delayed updateUIView")
                    }
                }
            }
        }
        
        // Asegurar que el adUnitID sea correcto
        if bannerView.adUnitID != adUnitID {
            bannerView.adUnitID = adUnitID
            let request = Request()
            bannerView.load(request)
            print("🔄 Banner reloaded with correct adUnitID")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
            DiagnosticsManager.shared.log("Banner loaded", type: .success)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
            DiagnosticsManager.shared.log("Banner failed: \(error.localizedDescription)", type: .error)
            
            // Reintentar cargar el banner después de un tiempo
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                print("🔄 Retrying banner load...")
                DiagnosticsManager.shared.log("Retrying banner...", type: .warning)
                bannerView.load(Request())
            }
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("🎯 Banner ad recorded impression")
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📱 Banner ad will present screen")
        }

        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            print("👋 Banner ad will dismiss screen")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("✅ Banner ad did dismiss screen")
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
        MobileAds.shared.start { status in
            print("🎯 Google Mobile Ads SDK initialized successfully")
            print("🎯 AdMob adapters status: \(status)")
            DiagnosticsManager.shared.adMobStatus = "Initialized"
            DiagnosticsManager.shared.log("AdMob SDK Initialized", type: .success)
        }
        
        // En producción (App Store), los anuncios de test se deshabilitan automáticamente
        // Los anuncios de "test mode" solo aparecen en desarrollo
        // Cuando la app esté en el App Store, AdMob automáticamente mostrará anuncios reales
        #if DEBUG
        print("🔧 DEBUG mode: Test ads will be shown")
        #else
        print("🚀 RELEASE mode: Production ads will be shown")
        #endif

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