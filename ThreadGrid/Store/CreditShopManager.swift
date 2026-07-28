import Foundation
import StoreKit

/// StoreKit2 consumable credit chain (checklist §9): yanran balance catalog,
/// verified purchases credit the ledger by catalog amount, transaction id is
/// recorded for reconciliation, and purchases are never re-credited —
/// consumables are spent, not recovered.
@MainActor
final class CreditShopManager: ObservableObject {

    enum PurchaseState: Equatable {
        case browsing
        case purchasing(String) // product id being purchased
        case success(amount: Int)
        case failed
    }

    @Published private(set) var storeProducts: [Product] = []
    @Published private(set) var productsLoadFailed = false
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseState: PurchaseState = .browsing

    private let appStore: AppStore
    private var updatesTask: Task<Void, Never>?

    init(appStore: AppStore) {
        self.appStore = appStore
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    func loadProducts() async {
        isLoadingProducts = true
        productsLoadFailed = false
        do {
            let ids = CreditCatalog.displayedProducts.map(\.productID)
            storeProducts = try await Product.products(for: ids)
            if storeProducts.isEmpty { productsLoadFailed = true }
        } catch {
            print("[ThreadGrid] storekit product load failed: \(error)")
            productsLoadFailed = true
            storeProducts = []
        }
        isLoadingProducts = false
    }

    /// Price shown next to a catalog row: StoreKit-localized when available,
    /// catalog reference price otherwise (row stays browsable, purchase retries load).
    func displayPrice(for catalogProduct: CreditCatalog.Product) -> String {
        storeProducts.first(where: { $0.id == catalogProduct.productID })?.displayPrice
            ?? catalogProduct.referencePrice
    }

    // MARK: - Purchase

    func purchase(_ catalogProduct: CreditCatalog.Product) async {
        guard case .browsing = purchaseState else { return } // no duplicate submissions
        purchaseState = .purchasing(catalogProduct.productID)

        // Ensure we have the live StoreKit product before purchasing.
        var storeProduct = storeProducts.first(where: { $0.id == catalogProduct.productID })
        if storeProduct == nil {
            await loadProducts()
            storeProduct = storeProducts.first(where: { $0.id == catalogProduct.productID })
        }
        guard let product = storeProduct else {
            purchaseState = .failed
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                appStore.creditPurchase(
                    amount: catalogProduct.amount,
                    storekitTransactionId: String(transaction.id)
                )
                await transaction.finish()
                purchaseState = .success(amount: catalogProduct.amount)
            case .userCancelled:
                purchaseState = .browsing // cancel is not a charge, never deducts
            case .pending:
                purchaseState = .browsing
            @unknown default:
                purchaseState = .failed
            }
        } catch {
            print("[ThreadGrid] purchase failed: \(error)")
            purchaseState = .failed
        }
    }

    func resetToBrowsing() {
        purchaseState = .browsing
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(transactionResult) else { return }
        if let catalogProduct = CreditCatalog.product(for: transaction.productID) {
            appStore.creditPurchase(
                amount: catalogProduct.amount,
                storekitTransactionId: String(transaction.id)
            )
        }
        await transaction.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
