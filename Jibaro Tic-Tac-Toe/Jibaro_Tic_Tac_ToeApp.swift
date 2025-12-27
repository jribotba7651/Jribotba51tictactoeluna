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


@main
struct Jibaro_Tic_Tac_ToeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}