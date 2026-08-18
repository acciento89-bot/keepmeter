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
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlements()
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

        do {
            lifetimeProduct = try await Product.products(for: [Self.lifetimeProductID]).first
            await refreshEntitlements()

            if lifetimeProduct == nil && !isPro {
                lastErrorMessage = String(localized: "Lifetime Pro is currently unavailable.")
            }
        } catch {
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
                guard case .verified(let transaction) = verification else {
                    lastErrorMessage = String(localized: "Purchase verification failed.")
                    return
                }

                await transaction.finish()
                await refreshEntitlements()

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
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var hasLifetime = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.productID == Self.lifetimeProductID && transaction.revocationDate == nil {
                hasLifetime = true
            }
        }

        isPro = hasLifetime
    }
}
