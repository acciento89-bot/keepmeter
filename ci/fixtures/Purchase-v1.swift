import Foundation
import SwiftData

enum PurchaseOutcome: String, Codable, CaseIterable {
    case active
    case kept
    case returned
}

@Model
final class Purchase {
    var id: UUID
    var name: String
    var merchant: String
    var price: Double
    var purchaseDate: Date
    var returnDeadline: Date
    var createdAt: Date
    var outcomeRawValue: String
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade)
    var usageEvents: [UsageEvent]

    init(
        id: UUID = UUID(),
        name: String,
        merchant: String = "",
        price: Double,
        purchaseDate: Date,
        returnDeadline: Date,
        createdAt: Date = .now,
        outcome: PurchaseOutcome = .active,
        archivedAt: Date? = nil,
        usageEvents: [UsageEvent] = []
    ) {
        self.id = id
        self.name = name
        self.merchant = merchant
        self.price = price
        self.purchaseDate = purchaseDate
        self.returnDeadline = returnDeadline
        self.createdAt = createdAt
        self.outcomeRawValue = outcome.rawValue
        self.archivedAt = archivedAt
        self.usageEvents = usageEvents
    }

    var outcome: PurchaseOutcome {
        get { PurchaseOutcome(rawValue: outcomeRawValue) ?? .active }
        set { outcomeRawValue = newValue.rawValue }
    }

    var useCount: Int {
        usageEvents.count
    }

    var costPerUse: Double? {
        guard useCount > 0 else { return nil }
        return price / Double(useCount)
    }

    var lastUsedAt: Date? {
        usageEvents.map(\.timestamp).max()
    }

    func daysRemaining(referenceDate: Date = .now, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.startOfDay(for: returnDeadline)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func returnWindowElapsedRatio(referenceDate: Date = .now) -> Double {
        let total = returnDeadline.timeIntervalSince(purchaseDate)
        guard total > 0 else { return 1 }
        let elapsed = referenceDate.timeIntervalSince(purchaseDate)
        return min(max(elapsed / total, 0), 1)
    }
}
