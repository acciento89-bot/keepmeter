import Foundation
@main struct PurchaseFilterSmoke {
 static func main() {
  precondition(PurchaseFilter.matches(name: "Kopfhörer", merchant: "Laden", category: "tech", daysRemaining: 2, query: "hör", categoryFilter: "all", dueSoon: false))
  precondition(PurchaseFilter.matches(name: "Kopfhörer", merchant: "Läden", category: "tech", daysRemaining: 7, query: "laden", categoryFilter: "tech", dueSoon: true))
  for days in [-1, 8] { precondition(!PurchaseFilter.matches(name: "A", merchant: "", category: "tech", daysRemaining: days, query: "", categoryFilter: "all", dueSoon: true)) }
  precondition(!PurchaseFilter.matches(name: "A", merchant: "", category: "tech", daysRemaining: 1, query: "", categoryFilter: "home", dueSoon: false))
  precondition(!PurchaseFilter.matches(name: "A", merchant: "", category: "tech", daysRemaining: 1, query: "missing", categoryFilter: "all", dueSoon: false))
  print("PurchaseFilter: 6 assertions passed")
 }
}
