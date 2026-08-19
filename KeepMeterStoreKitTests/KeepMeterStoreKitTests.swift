import XCTest
import StoreKit
import StoreKitTest
@testable import KeepMeter

final class KeepMeterStoreKitTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        continueAfterFailure = false

        guard let configurationURL = Bundle(for: Self.self).url(
            forResource: "KeepMeter",
            withExtension: "storekit"
        ) else {
            XCTFail("KeepMeter.storekit is missing from the StoreKit test bundle")
            return
        }

        session = try SKTestSession(contentsOf: configurationURL)
        session.disableDialogs = true
        session.resetToDefaultState()
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session?.clearTransactions()
        session = nil
    }

    @MainActor
    func testLifetimePurchaseUnlocksAndRecoversAcrossStoreRecreation() async throws {
        let store = EntitlementStore()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPro, "A clean StoreKit test session must begin on Free")

        let transaction = try await session.buyProduct(
            identifier: EntitlementStore.lifetimeProductID
        )

        XCTAssertEqual(
            transaction.productID,
            EntitlementStore.lifetimeProductID,
            "StoreKitTest returned a transaction for the wrong product"
        )

        await store.refreshEntitlements()
        XCTAssertTrue(
            store.isPro,
            "Lifetime Pro must unlock from Transaction.currentEntitlements"
        )

        let recreatedStore = EntitlementStore()
        await recreatedStore.refreshEntitlements()
        XCTAssertTrue(
            recreatedStore.isPro,
            "A newly-created EntitlementStore must recover the Lifetime entitlement without a fake Pro flag or manual sync"
        )

        session.clearTransactions()
        await store.refreshEntitlements()
        await recreatedStore.refreshEntitlements()

        XCTAssertFalse(store.isPro, "Removing the StoreKit test transaction must remove Pro")
        XCTAssertFalse(
            recreatedStore.isPro,
            "Removing the StoreKit test transaction must remove the recovered Pro entitlement"
        )
    }
}
