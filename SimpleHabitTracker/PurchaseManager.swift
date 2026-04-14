import Foundation
import StoreKit

@Observable
@MainActor
final class PurchaseManager {
    static let productID = "com.thorbjxrn.simplehabittracker.premium"
    private static let isPremiumKey = "isPremiumCached"

    private(set) var product: Product?
    private(set) var isPremium: Bool = false
    private(set) var isLoading: Bool = false
    var errorMessage: String?

    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

    init() {
        // Start with false - don't trust cache until verified
        isPremium = false

        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Load products and verify entitlement
        Task {
            await loadProducts()
            await verifyEntitlement()
        }
    }

    deinit {
        let listener = transactionListener
        listener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product else {
            errorMessage = "Product not available. Please try again later."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                updatePremiumStatus(true)

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await verifyEntitlement()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Verify Entitlement

    private func verifyEntitlement() async {
        do {
            let result = await Transaction.currentEntitlement(for: Self.productID)
            if let result {
                let transaction = try checkVerified(result)
                _ = transaction
                updatePremiumStatus(true)
            } else {
                updatePremiumStatus(false)
            }
        } catch {
            // If verification fails, rely on cached value
            print("Entitlement verification error: \(error)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction {
                        await transaction.finish()
                        await self?.verifyEntitlement()
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func updatePremiumStatus(_ newValue: Bool) {
        isPremium = newValue
        UserDefaults.standard.set(newValue, forKey: Self.isPremiumKey)
    }

    // MARK: - Debug

    #if DEBUG
    func debugTogglePremium() {
        updatePremiumStatus(!isPremium)
    }
    #endif
}
