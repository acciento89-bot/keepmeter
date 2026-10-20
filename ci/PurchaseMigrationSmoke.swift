import Foundation
import SwiftData
@main struct PurchaseMigrationSmoke {
 static func main() throws {
  let url = URL(fileURLWithPath: CommandLine.arguments[2])
  let schema = Schema([Purchase.self, UsageEvent.self])
  let container = try ModelContainer(for: schema, configurations: [ModelConfiguration("MigrationQA", schema: schema, url: url, cloudKitDatabase: .none)])
  let context = ModelContext(container)
  if CommandLine.arguments[1] == "seed" {
   let item = Purchase(name: "Old purchase", merchant: "QA", price: 72, purchaseDate: Date(timeIntervalSince1970: 1700000000), returnDeadline: Date(timeIntervalSince1970: 1701000000))
   item.usageEvents = [UsageEvent(timestamp: Date(timeIntervalSince1970: 1700000100))]
   context.insert(item);try context.save();print("Legacy store seeded")
  } else {
   let items = try context.fetch(FetchDescriptor<Purchase>())
   precondition(items.count == 1 && items[0].name == "Old purchase" && items[0].useCount == 1)
#if NEW_SCHEMA
   let item = items[0]
   if CommandLine.arguments[1] == "migrate" {
    precondition(item.categoryRawValue == "other" && item.receiptPhoto == nil)
    item.categoryRawValue = "tech";item.receiptPhoto = Data([1,2,3]);try context.save()
   } else { precondition(item.categoryRawValue == "tech" && item.receiptPhoto == Data([1,2,3])) }
#endif
   print("Migration/receipt persistence verified")
  }
 }
}
