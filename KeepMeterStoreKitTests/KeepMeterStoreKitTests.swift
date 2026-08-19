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
    private func waitForEntitlement(
        _ expected: Bool,
        in store: EntitlementStore,
        attempts: Int = 50
    ) async -> Bool {
        for _ in 0..<attempts {
            // An externally-created StoreKitTest transaction arrives asynchronously.
            // Give Transaction.updates a chance to grant access first, then also
            // exercise the production recovery path via currentEntitlements.
            if store.isPro == expected {
                return true
            }

            await store.refreshEntitlements()
            if store.isPro == expected {
                return true
            }

            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        await store.refreshEntitlements()
        return store.isPro == expected
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

        let unlocked = await waitForEntitlement(true, in: store)
        XCTAssertTrue(
            unlocked,
            "Lifetime Pro must unlock after the external StoreKitTest transaction propagates through Transaction.updates/currentEntitlements"
        )

        let recreatedStore = EntitlementStore()
        let recovered = await waitForEntitlement(true, in: recreatedStore)
        XCTAssertTrue(
            recovered,
            "A newly-created EntitlementStore must recover the Lifetime entitlement without a fake Pro flag or manual sync"
        )

        session.clearTransactions()

        let removedFromOriginalStore = await waitForEntitlement(false, in: store)
        XCTAssertTrue(
            removedFromOriginalStore,
            "Removing the StoreKit test transaction must remove Pro"
        )

        let removedFromRecreatedStore = await waitForEntitlement(false, in: recreatedStore)
        XCTAssertTrue(
            removedFromRecreatedStore,
            "Removing the StoreKit test transaction must remove the recovered Pro entitlement"
        )
    }
}
