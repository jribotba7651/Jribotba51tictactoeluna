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

    // Usar product ID de test en DEBUG mode
    private let removeAdsProductID: String = {
        #if DEBUG
        // En DEBUG mode, usamos un ID que no existe para evitar errores de validación
        // Los IAP no funcionan en simulator de todas formas
        return "com.test.removeads.debug"
        #else
        return "com.jibaroenlaluna.tictactoe.removeads"
        #endif
    }()
    private var products: [SKProduct] = []

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadPurchaseStatus()
        requestProducts()
        print("PurchaseManager initialized")
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
        print("Requesting products: \(removeAdsProductID)")
    }

    func purchaseRemoveAds() {
        guard let product = products.first(where: { $0.productIdentifier == removeAdsProductID }) else {
            print("❌ Product not found: \(removeAdsProductID)")
            print("Purchase failed: Product not found")
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
        print("Initiating purchase for: \(removeAdsProductID)")
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
            print("Products loaded: \(response.products.count)")

            if response.invalidProductIdentifiers.count > 0 {
                print("⚠️ Invalid product identifiers: \(response.invalidProductIdentifiers)")
                let errorMsg = "Algunos productos no son válidos. Por favor, contacta al soporte."
                self.errorMessage = errorMsg
                print("Invalid Product IDs: \(response.invalidProductIdentifiers)")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Failed to load products: \(error.localizedDescription)")
            let errorMsg = "Error al cargar productos: \(error.localizedDescription)"
            self.errorMessage = errorMsg
            print("Failed to load products: \(error.localizedDescription)")
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
                print("Purchase successful: \(transaction.payment.productIdentifier)")
                completePurchase(transaction)
            case .failed:
                let errorMessage = transaction.error?.localizedDescription ?? "Unknown error"
                print("❌ Purchase failed: \(errorMessage)")
                print("Purchase failed: \(errorMessage)")
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
            print("Restore failed: \(error.localizedDescription)")
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


// Ad logic injected into specific views to solve visibility issues.



// AppDelegate para inicializar AdMob
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Inicializar Google Mobile Ads SDK
        MobileAds.shared.start { status in
            print("🎯 Google Mobile Ads SDK initialized successfully")
            print("🎯 AdMob adapters status: \(status)")
            print("AdMob SDK Initialized")
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