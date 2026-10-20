import Foundation

enum PurchaseFilter {
    static func matches(name: String, merchant: String, category: String, daysRemaining: Int,
                        query: String, categoryFilter: String, dueSoon: Bool) -> Bool {
        if categoryFilter != "all" && category != categoryFilter { return false }
        if dueSoon && !(0...7).contains(daysRemaining) { return false }
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty || (name + " " + merchant).range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

enum PurchaseCategory: String, CaseIterable, Identifiable {
    case other, tech, clothing, home, leisure, gifts
    var id: String { rawValue }
    var title: String {
        switch self {
        case .other: String(localized: "Other")
        case .tech: String(localized: "Technology")
        case .clothing: String(localized: "Clothing")
        case .home: String(localized: "Home")
        case .leisure: String(localized: "Leisure")
        case .gifts: String(localized: "Gifts")
        }
    }
}
