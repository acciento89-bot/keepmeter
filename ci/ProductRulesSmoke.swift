import Foundation
import SwiftData

private enum SmokeFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): return message
        }
    }
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw SmokeFailure.failed(message) }
}

private func makePurchase(
    reference: Date,
    purchaseOffsetDays: Int,
    deadlineOffsetDays: Int,
    uses: Int,
    price: Double = 120
) -> Purchase {
    let calendar = Calendar.current
    let purchaseDate = calendar.date(byAdding: .day, value: purchaseOffsetDays, to: reference)!
    let returnDeadline = calendar.date(byAdding: .day, value: deadlineOffsetDays, to: reference)!
    let usageEvents = (0..<uses).map { index in
        UsageEvent(timestamp: calendar.date(byAdding: .hour, value: -index, to: reference)!)
    }

    return Purchase(
        name: "Smoke purchase",
        price: price,
        purchaseDate: purchaseDate,
        returnDeadline: returnDeadline,
        usageEvents: usageEvents
    )
}

@main
struct ProductRulesSmoke {
    static func main() throws {
        let calendar = Calendar.current
        let reference = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

        let expired = makePurchase(reference: reference, purchaseOffsetDays: -10, deadlineOffsetDays: -1, uses: 4)
        let expiredSnapshot = DecisionEngine.evaluate(expired, referenceDate: reference)
        try expect(expiredSnapshot.status == .review, "Expired purchase must be REVIEW")
        try expect(expiredSnapshot.reason == .deadlinePassed, "Expired purchase must use deadlinePassed reason")

        let unusedUrgent = makePurchase(reference: reference, purchaseOffsetDays: -10, deadlineOffsetDays: 2, uses: 0)
        let unusedUrgentSnapshot = DecisionEngine.evaluate(unusedUrgent, referenceDate: reference)
        try expect(unusedUrgentSnapshot.status == .returnCandidate, "Unused purchase with <=3 days left must be RETURN?")
        try expect(unusedUrgentSnapshot.reason == .unusedUrgent, "Unused urgent purchase must use unusedUrgent reason")

        let lightlyUsedUrgent = makePurchase(reference: reference, purchaseOffsetDays: -10, deadlineOffsetDays: 2, uses: 1)
        let lightlyUsedUrgentSnapshot = DecisionEngine.evaluate(lightlyUsedUrgent, referenceDate: reference)
        try expect(lightlyUsedUrgentSnapshot.status == .review, "Lightly used urgent purchase must be REVIEW")
        try expect(lightlyUsedUrgentSnapshot.reason == .lightlyUsedUrgent, "Lightly used urgent purchase must use lightlyUsedUrgent reason")

        let unusedLate = makePurchase(reference: reference, purchaseOffsetDays: -8, deadlineOffsetDays: 4, uses: 0)
        let unusedLateSnapshot = DecisionEngine.evaluate(unusedLate, referenceDate: reference)
        try expect(unusedLateSnapshot.status == .review, "Unused late-window purchase must be REVIEW")
        try expect(unusedLateSnapshot.reason == .unusedLateWindow, "Unused late-window purchase must use unusedLateWindow reason")

        let repeatedUse = makePurchase(reference: reference, purchaseOffsetDays: -3, deadlineOffsetDays: 10, uses: 3)
        let repeatedUseSnapshot = DecisionEngine.evaluate(repeatedUse, referenceDate: reference)
        try expect(repeatedUseSnapshot.status == .keep, "Three or more uses must produce KEEP while deadline is open")
        try expect(repeatedUseSnapshot.reason == .repeatedUse, "Repeated use must use repeatedUse reason")
        try expect(repeatedUseSnapshot.costPerUse == 40, "Cost per use must be price divided by use count")

        let earlyWindow = makePurchase(reference: reference, purchaseOffsetDays: -1, deadlineOffsetDays: 13, uses: 1)
        let earlyWindowSnapshot = DecisionEngine.evaluate(earlyWindow, referenceDate: reference)
        try expect(earlyWindowSnapshot.status == .review, "Early-window purchase must be REVIEW")
        try expect(earlyWindowSnapshot.reason == .earlyWindow, "Early-window purchase must use earlyWindow reason")

        let needsMoreSignal = makePurchase(reference: reference, purchaseOffsetDays: -7, deadlineOffsetDays: 7, uses: 2)
        let needsMoreSignalSnapshot = DecisionEngine.evaluate(needsMoreSignal, referenceDate: reference)
        try expect(needsMoreSignalSnapshot.status == .review, "Mid-window purchase with two uses must be REVIEW")
        try expect(needsMoreSignalSnapshot.reason == .needsMoreSignal, "Mid-window purchase must use needsMoreSignal reason")

        let malformedWindow = Purchase(
            name: "Malformed window",
            price: 10,
            purchaseDate: reference,
            returnDeadline: calendar.date(byAdding: .day, value: -1, to: reference)!
        )
        try expect(malformedWindow.returnWindowElapsedRatio(referenceDate: reference) == 1, "Invalid/non-positive return windows must clamp to elapsed ratio 1")

        let dashboardSource = try String(contentsOfFile: "KeepMeter/Views/DashboardView.swift", encoding: .utf8)
        try expect(dashboardSource.contains("private let freeActivePurchaseLimit = 5"), "Free active purchase limit must remain 5 in v1")
        try expect(dashboardSource.contains("activePurchases.count >= freeActivePurchaseLimit"), "Dashboard must enforce the free limit before presenting Add Purchase")

        print("✓ DecisionEngine branch coverage")
        print("✓ Cost-per-use behavior")
        print("✓ Invalid return-window clamp")
        print("✓ Free-tier UI contract = 5 active purchases")
        print("KeepMeter product rule smoke passed")
    }
}
