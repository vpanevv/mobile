import Foundation
import Combine
import StoreKit

/// StoreKit 2 store for WishlyAI Pro.
/// Pro unlocks: unlimited daily wishes + Card Mode (create & share wish cards).
@MainActor
final class ProStore: ObservableObject {
    static let shared = ProStore()

    static let monthlyID  = "com.vladipanev.wishlyai.pro.monthly"
    static let lifetimeID = "com.vladipanev.wishlyai.pro.lifetime"
    static var productIDs: Set<String> { [monthlyID, lifetimeID] }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoadingProducts = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Listen for transactions that happen outside the app (renewals, refunds,
        // purchases on another device) for the lifetime of the singleton.
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            // Subscriptions first, lifetime second
            products = loaded.sorted { a, b in
                (a.type == .autoRenewable ? 0 : 1) < (b.type == .autoRenewable ? 0 : 1)
            }
        } catch {
            // Network/App Store hiccup — paywall offers a retry via re-calling this.
        }
    }

    func refreshEntitlements() async {
        var pro = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
    }

    /// Returns true when the purchase completed and was verified.
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
