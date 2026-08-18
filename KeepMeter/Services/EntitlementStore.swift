import Foundation
import Combine
import StoreKit

@MainActor
final class EntitlementStore: ObservableObject {
    static let lifetimeProductID = "de.kamilunavo.keepmeter.pro.lifetime"

    @Published private(set) var isPro = false
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoading = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }

                switch update {
                case .verified(let transaction):
                    await self.processVerifiedTransaction(transaction)
                case .unverified:
                    // Never unlock paid features from an unverified transaction.
                    continue
                }
            }
        }

        Task {
            await load()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func load() async {
        lastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // Entitlement recovery is intentionally independent from product loading.
        // A Lifetime Pro customer must remain Pro even when Product.products(for:)
        // is temporarily unavailable because of network/App Store conditions.
        await refreshEntitlements()
        await finishUnfinishedLifetimeTransactions()

        do {
            lifetimeProduct = try await Product.products(for: [Self.lifetimeProductID]).first

            if lifetimeProduct == nil && !isPro {
                lastErrorMessage = String(localized: "Lifetime Pro is currently unavailable.")
            }
        } catch {
            // Preserve the already-refreshed entitlement state. Product metadata is
            // useful for purchasing/display price, but it must never be the source
            // of truth for an existing non-consumable entitlement.
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchaseLifetime() async {
        lastErrorMessage = nil

        if lifetimeProduct == nil {
            await load()
        }

        guard let lifetimeProduct else {
            if lastErrorMessage == nil {
                lastErrorMessage = String(localized: "Lifetime Pro is currently unavailable.")
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await lifetimeProduct.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    guard transaction.productID == Self.lifetimeProductID else {
                        lastErrorMessage = String(localized: "Purchase verification failed.")
                        return
                    }

                    // Grant/refresh access before finishing the transaction.
                    await processVerifiedTransaction(transaction)

                case .unverified:
                    lastErrorMessage = String(localized: "Purchase verification failed.")
                }

            case .pending:
                lastErrorMessage = String(localized: "The purchase is pending approval.")

            case .userCancelled:
                break

            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        lastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // AppStore.sync() is intentionally only called from this explicit user
            // action. Normal launches recover from currentEntitlements automatically.
            try await AppStore.sync()
            await refreshEntitlements()
            await finishUnfinishedLifetimeTransactions()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var hasLifetime = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard transaction.productID == Self.lifetimeProductID else { continue }

            // Refunded/revoked non-consumables aren't normally emitted by
            // currentEntitlements, but keep the explicit guard for defense in depth.
            if transaction.revocationDate == nil {
                hasLifetime = true
            }
        }

        isPro = hasLifetime
    }

    private func processVerifiedTransaction(_ transaction: Transaction) async {
        guard transaction.productID == Self.lifetimeProductID else { return }

        // StoreKit recommends granting access before finish(). This also protects
        // the narrow app-termination window between a successful purchase and the
        // next entitlement refresh.
        if transaction.revocationDate == nil {
            isPro = true
        } else {
            isPro = false
        }

        await transaction.finish()
        await refreshEntitlements()
    }

    private func finishUnfinishedLifetimeTransactions() async {
        var processedTransaction = false

        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.lifetimeProductID else { continue }

            processedTransaction = true

            // Grant access first, then finish. This recovers a transaction if the
            // app previously terminated after purchase but before finish().
            if transaction.revocationDate == nil {
                isPro = true
            }

            await transaction.finish()
        }

        if processedTransaction {
            await refreshEntitlements()
        }
    }
}
