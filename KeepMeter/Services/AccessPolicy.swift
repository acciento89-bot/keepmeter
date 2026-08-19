import Foundation

enum AccessPolicy {
    static let freeActivePurchaseLimit = 5

    static func canAddActivePurchase(activePurchaseCount: Int, isPro: Bool) -> Bool {
        isPro || activePurchaseCount < freeActivePurchaseLimit
    }

    static func hasReachedFreeLimit(activePurchaseCount: Int, isPro: Bool) -> Bool {
        !canAddActivePurchase(activePurchaseCount: activePurchaseCount, isPro: isPro)
    }
}
