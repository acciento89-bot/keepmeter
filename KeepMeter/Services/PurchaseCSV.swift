import Foundation

/// A read-only spreadsheet snapshot. No persistent data is changed during export.
enum PurchaseCSV {
    struct Row {
        let name: String
        let merchant: String
        let price: Double
        let currency: String
        let purchaseDate: String
        let returnDate: String
        let outcome: String
        let uses: Int
        var category: String = "Other"
    }

    static func encode(_ rows: [Row], german: Bool) -> String {
        let headers = german
            ? ["Kauf", "Händler", "Preis", "Währung", "Kaufdatum", "Rückgabedatum", "Status", "Nutzungen", "Kosten pro Nutzung", "Kategorie"]
            : ["Purchase", "Merchant", "Price", "Currency", "Purchase date", "Return date", "Status", "Uses", "Cost per use", "Category"]
        var lines = [headers.map(cell).joined(separator: ",")]
        for row in rows {
            let status: String
            switch row.outcome {
            case "kept": status = german ? "Behalten" : "Kept"
            case "returned": status = german ? "Zurückgegeben" : "Returned"
            default: status = german ? "Aktiv" : "Active"
            }
            let fields = [row.name, row.merchant, number(row.price), row.currency, row.purchaseDate,
                          row.returnDate, status, String(row.uses), row.uses > 0 ? number(row.price / Double(row.uses)) : "", row.category]
            lines.append(fields.map(cell).joined(separator: ","))
        }
        // Excel recognises Unicode with a BOM. CRLF and quoted cells also work in Numbers.
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func number(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private static func cell(_ value: String) -> String {
        // Quoting alone does not prevent a spreadsheet interpreting a user-entered formula.
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let guarded = trimmed.first.map { "=+-@".contains($0) } == true ? "'" + value : value
        return "\"" + guarded.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
