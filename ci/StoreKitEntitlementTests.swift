import XCTest
import StoreKit
import StoreKitTest
@testable import KeepMeterEntitlement

final class KeepMeterStoreKitTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        let configURL = try XCTUnwrap(
            Bundle.module.url(forResource: "KeepMeter", withExtension: "storekit"),
            "KeepMeter.storekit must be bundled into the StoreKit test harness"
        )

        session = try SKTestSession(contentsOf: configURL)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        session = nil
    }

    @MainActor
    func testLifetimePurchaseAndEntitlementRecovery() async throws {
        do {
            let store = EntitlementStore()
            await store.load()

            XCTAssertFalse(store.isPro, "A clean StoreKit session must begin on the Free tier")
            XCTAssertNotNil(store.lifetimeProduct, "Lifetime Pro metadata must load from KeepMeter.storekit")

            await store.purchaseLifetime()

            XCTAssertTrue(
                store.isPro,
                store.lastErrorMessage ?? "purchaseLifetime() must unlock Lifetime Pro"
            )
        }

        do {
            let relaunchedStore = EntitlementStore()
            await relaunchedStore.load()

            XCTAssertTrue(
                relaunchedStore.isPro,
                "A new EntitlementStore must recover the non-consumable from currentEntitlements"
            )
        }

        session.clearTransactions()

        do {
            let clearedStore = EntitlementStore()
            await clearedStore.load()
            XCTAssertFalse(
                clearedStore.isPro,
                "Clearing StoreKit test transactions must return a fresh install to the Free tier"
            )
        }

        _ = try await session.buyProduct(
            identifier: EntitlementStore.lifetimeProductID,
            options: []
        )

        do {
            let externallyPurchasedStore = EntitlementStore()
            await externallyPurchasedStore.load()

            XCTAssertTrue(
                externallyPurchasedStore.isPro,
                "An externally-created verified Lifetime transaction must be recovered as Pro"
            )
        }
    }
}
