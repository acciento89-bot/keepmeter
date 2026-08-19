import Foundation
import StoreKit
import StoreKitTest

private enum SmokeFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self {
        case .assertion(let message):
            return message
        }
    }
}

@main
struct StoreKitEntitlementSmoke {
    @MainActor
    static func main() async throws {
        let configurationURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("KeepMeter/StoreKit/KeepMeter.storekit")

        guard FileManager.default.fileExists(atPath: configurationURL.path) else {
            throw SmokeFailure.assertion("StoreKit configuration is missing: \(configurationURL.path)")
        }

        let session = try SKTestSession(contentsOf: configurationURL)
        session.disableDialogs = true
        session.resetToDefaultState()
        session.clearTransactions()

        let store = EntitlementStore()
        await store.refreshEntitlements()
        try require(!store.isPro, "Fresh StoreKit test session must begin on Free")

        let purchasedTransaction = try await session.buyProduct(
            identifier: EntitlementStore.lifetimeProductID
        )

        try require(
            purchasedTransaction.productID == EntitlementStore.lifetimeProductID,
            "StoreKitTest returned the wrong product transaction"
        )

        await store.refreshEntitlements()
        try require(store.isPro, "Lifetime purchase must unlock Pro through currentEntitlements")

        let relaunchedStore = EntitlementStore()
        await relaunchedStore.refreshEntitlements()
        try require(
            relaunchedStore.isPro,
            "A new EntitlementStore must recover Lifetime Pro without a fake entitlement or manual sync"
        )

        session.clearTransactions()
        await store.refreshEntitlements()
        await relaunchedStore.refreshEntitlements()
        try require(!store.isPro, "Clearing the StoreKit test transaction must remove Pro")
        try require(!relaunchedStore.isPro, "Clearing the StoreKit test transaction must remove recovered Pro")

        print("✓ Fresh StoreKitTest session starts Free")
        print("✓ Lifetime Non-Consumable purchase created for \(EntitlementStore.lifetimeProductID)")
        print("✓ currentEntitlements unlocks the live EntitlementStore")
        print("✓ A newly-created EntitlementStore recovers Lifetime Pro")
        print("✓ Clearing StoreKitTest transactions removes the entitlement")
        print("KeepMeter StoreKit entitlement smoke passed")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw SmokeFailure.assertion(message)
        }
    }
}
