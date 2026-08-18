import Foundation
import SwiftData

enum PersistenceSmokeError: Error, CustomStringConvertible {
    case checkFailed(String)

    var description: String {
        switch self {
        case .checkFailed(let message):
            return message
        }
    }
}

@main
struct PersistenceSmoke {
    private static let purchaseID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let eventID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let purchaseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private static let returnDeadline = Date(timeIntervalSince1970: 1_701_209_600)
    private static let eventTimestamp = Date(timeIntervalSince1970: 1_700_086_400)
    private static let archivedAt = Date(timeIntervalSince1970: 1_700_172_800)

    static func main() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("KeepMeterPersistenceSmoke-\(UUID().uuidString).store")

        defer {
            cleanupStore(at: storeURL)
        }

        try writeFixture(to: storeURL)
        try verifyFixture(afterReopening: storeURL)

        print("KeepMeter persistence smoke test passed")
    }

    private static func makeContainer(storeURL: URL) throws -> ModelContainer {
        let schema = Schema([Purchase.self, UsageEvent.self])
        let configuration = ModelConfiguration(
            "KeepMeterPersistenceSmoke",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    private static func writeFixture(to storeURL: URL) throws {
        let container = try makeContainer(storeURL: storeURL)
        let context = ModelContext(container)
        context.autosaveEnabled = false

        let purchase = Purchase(
            id: purchaseID,
            name: "Persistence Headphones",
            merchant: "KeepMeter QA",
            price: 149.99,
            purchaseDate: purchaseDate,
            returnDeadline: returnDeadline
        )
        context.insert(purchase)

        let usage = UsageEvent(id: eventID, timestamp: eventTimestamp)
        context.insert(usage)
        purchase.usageEvents.append(usage)
        purchase.outcome = .kept
        purchase.archivedAt = archivedAt

        try context.save()

        guard !context.hasChanges else {
            throw PersistenceSmokeError.checkFailed("Context still has unsaved changes after fixture save")
        }
    }

    private static func verifyFixture(afterReopening storeURL: URL) throws {
        let container = try makeContainer(storeURL: storeURL)
        let context = ModelContext(container)
        context.autosaveEnabled = false

        let purchases = try context.fetch(FetchDescriptor<Purchase>())

        guard purchases.count == 1, let purchase = purchases.first else {
            throw PersistenceSmokeError.checkFailed("Expected exactly one persisted purchase after reopening")
        }

        guard purchase.id == purchaseID else {
            throw PersistenceSmokeError.checkFailed("Purchase ID did not survive store reopen")
        }
        guard purchase.name == "Persistence Headphones" else {
            throw PersistenceSmokeError.checkFailed("Purchase name did not survive store reopen")
        }
        guard purchase.merchant == "KeepMeter QA" else {
            throw PersistenceSmokeError.checkFailed("Merchant did not survive store reopen")
        }
        guard abs(purchase.price - 149.99) < 0.0001 else {
            throw PersistenceSmokeError.checkFailed("Purchase price did not survive store reopen")
        }
        guard purchase.purchaseDate == purchaseDate, purchase.returnDeadline == returnDeadline else {
            throw PersistenceSmokeError.checkFailed("Purchase dates did not survive store reopen")
        }
        guard purchase.outcome == .kept else {
            throw PersistenceSmokeError.checkFailed("Archived outcome did not survive store reopen")
        }
        guard purchase.archivedAt == archivedAt else {
            throw PersistenceSmokeError.checkFailed("Archive timestamp did not survive store reopen")
        }
        guard purchase.useCount == 1, let usage = purchase.usageEvents.first else {
            throw PersistenceSmokeError.checkFailed("Usage relationship did not survive store reopen")
        }
        guard usage.id == eventID, usage.timestamp == eventTimestamp else {
            throw PersistenceSmokeError.checkFailed("Usage event fields did not survive store reopen")
        }
        guard purchase.costPerUse != nil, abs((purchase.costPerUse ?? 0) - 149.99) < 0.0001 else {
            throw PersistenceSmokeError.checkFailed("Derived cost-per-use is inconsistent after store reopen")
        }
    }

    private static func cleanupStore(at storeURL: URL) {
        let fileManager = FileManager.default
        let relatedPaths = [
            storeURL.path,
            storeURL.path + "-shm",
            storeURL.path + "-wal"
        ]

        for path in relatedPaths where fileManager.fileExists(atPath: path) {
            try? fileManager.removeItem(atPath: path)
        }
    }
}
