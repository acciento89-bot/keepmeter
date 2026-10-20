import Foundation
@main struct PurchaseCSVSmoke {
 static func main() {
  let row = PurchaseCSV.Row(name: "Kopfhörer, \"Pro\"\nNeu", merchant: " =HYPERLINK(\"bad\")", price: 179.9, currency: "EUR", purchaseDate: "2026-10-01", returnDate: "2026-10-30", outcome: "active", uses: 2)
  let csv = PurchaseCSV.encode([row], german: true)
  precondition(csv.hasPrefix("\u{FEFF}\"Kauf\",\"Händler\""))
  precondition(csv.contains("\"Kopfhörer, \"\"Pro\"\"\nNeu\""))
  precondition(csv.contains("\"' =HYPERLINK(\"\"bad\"\")\""))
  precondition(csv.contains("\"179.90\",\"EUR\""))
  precondition(csv.contains("\"Aktiv\",\"2\",\"89.95\",\"Other\"\r\n"))
  let empty = PurchaseCSV.encode([], german: false)
  precondition(empty.contains("\"Purchase\""))
  precondition(empty.components(separatedBy: "\r\n").count == 2)
  let unused = PurchaseCSV.Row(name: "=1+1", merchant: "", price: 1, currency: "EUR", purchaseDate: "", returnDate: "", outcome: "returned", uses: 0)
  let zero = PurchaseCSV.encode([unused], german: false)
  precondition(zero.contains("\"'=1+1\""))
  precondition(zero.contains("\"Returned\",\"0\",\"\",\"Other\"\r\n"))
  print("PurchaseCSV: 9 export assertions passed")
 }
}
