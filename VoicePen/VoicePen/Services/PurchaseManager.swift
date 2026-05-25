import Foundation
import StoreKit

@Observable
final class PurchaseManager {
    var isPro = false
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    static let shared = PurchaseManager()

    private var transactionListener: Task<Void, Never>?
    let freeMonthlyLimit = 5

    private let productIDs = [
        "com.zzoutuo.VoicePen.pro.monthly",
        "com.zzoutuo.VoicePen.pro.yearly",
        "com.zzoutuo.VoicePen.pro.lifetime"
    ]

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var monthlyProduct: Product? {
        products.first { $0.id == productIDs[0] }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == productIDs[1] }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == productIDs[2] }
    }

    var activeSubscription: Product? {
        if let yearly = yearlyProduct, purchasedProductIDs.contains(yearly.id) {
            return yearly
        }
        if let monthly = monthlyProduct, purchasedProductIDs.contains(monthly.id) {
            return monthly
        }
        return nil
    }

    var isLifetimePurchased: Bool {
        if let lifetime = lifetimeProduct {
            return purchasedProductIDs.contains(lifetime.id)
        }
        return false
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchaseStatus()
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            print("Restore failed: \(error)")
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchaseStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchaseStatus() async {
        var purchased: Set<String> = []

        for productID in productIDs {
            if let result = await Transaction.currentEntitlement(for: productID) {
                if let transaction = try? checkVerified(result) {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
        isPro = !purchased.isEmpty
    }

    enum StoreError: Error {
        case failedVerification
    }
}
