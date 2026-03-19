import Foundation
import Combine
import StoreKit

@MainActor
final class SmartAISubscriptionStore: ObservableObject {
    @Published private(set) var smartAIProduct: Product?
    @Published private(set) var hasSmartAIAccess = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var statusMessage: String?

    private var updatesTask: Task<Void, Never>?
    private let appAccountToken: UUID
    private let userDefaults = UserDefaults.standard

    init() {
        self.appAccountToken = Self.loadOrCreateAppAccountToken()
        updatesTask = observeTransactions()

        Task {
            await refresh()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func purchaseSmartAI() async {
        guard let product = smartAIProduct else {
            statusMessage = "Smart AI subscription is not available yet."
            return
        }

        purchaseState = .purchasing
        statusMessage = nil

        do {
            let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])

            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                hasSmartAIAccess = true
                purchaseState = .purchased
                await transaction.finish()
                statusMessage = "Smart AI unlocked."
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .pending
                statusMessage = "Purchase is pending approval."
            @unknown default:
                purchaseState = .idle
                statusMessage = "Purchase state is not supported."
            }
        } catch {
            purchaseState = .failed
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseState = .restoring
        statusMessage = nil

        do {
            try await StoreKit.AppStore.sync()
            await refreshEntitlements()
            purchaseState = hasSmartAIAccess ? .purchased : .idle
            if hasSmartAIAccess {
                statusMessage = "Smart AI restored."
            } else {
                statusMessage = "No active Smart AI subscription was found."
            }
        } catch {
            purchaseState = .failed
            statusMessage = error.localizedDescription
        }
    }

    func currentEntitlementProof() async throws -> SmartAIEntitlementProof {
        for await result in Transaction.currentEntitlements {
            let transaction = try verify(result)
            guard transaction.productID == AppConfiguration.smartAIProductID else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate < .now {
                continue
            }

            return SmartAIEntitlementProof(
                signedTransactionInfo: result.jwsRepresentation,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                appAccountToken: transaction.appAccountToken?.uuidString ?? appAccountToken.uuidString
            )
        }

        throw StoreError.missingEntitlementProof
    }

    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [AppConfiguration.smartAIProductID])
            smartAIProduct = products.first
        } catch {
            statusMessage = "Failed to load subscription: \(error.localizedDescription)"
        }
    }

    private func refreshEntitlements() async {
        var hasAccess = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verify(result) else { continue }
            guard transaction.productID == AppConfiguration.smartAIProductID else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate < .now {
                continue
            }

            hasAccess = true
        }

        hasSmartAIAccess = hasAccess
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) {
            for await update in Transaction.updates {
                guard let transaction = try? Self.verify(update) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verify<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    nonisolated private static func verify<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

extension SmartAISubscriptionStore {
    struct SmartAIEntitlementProof {
        let signedTransactionInfo: String
        let transactionId: String
        let originalTransactionId: String
        let appAccountToken: String
    }

    enum PurchaseState {
        case idle
        case purchasing
        case restoring
        case purchased
        case pending
        case failed
    }

    enum StoreError: LocalizedError {
        case failedVerification
        case missingEntitlementProof

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "The App Store could not verify this transaction."
            case .missingEntitlementProof:
                return "Smart AI entitlement proof is not available for this account."
            }
        }
    }
}

private extension SmartAISubscriptionStore {
    static func loadOrCreateAppAccountToken() -> UUID {
        let defaults = UserDefaults.standard
        let key = "todoai.smartAI.appAccountToken"

        if let existing = defaults.string(forKey: key), let uuid = UUID(uuidString: existing) {
            return uuid
        }

        let newUUID = UUID()
        defaults.set(newUUID.uuidString, forKey: key)
        return newUUID
    }
}
