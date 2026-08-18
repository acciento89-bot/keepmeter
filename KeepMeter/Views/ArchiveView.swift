import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query(sort: \Purchase.archivedAt, order: .reverse) private var purchases: [Purchase]

    private var archivedPurchases: [Purchase] {
        purchases.filter { $0.outcome != .active }
    }

    var body: some View {
        NavigationStack {
            Group {
                if archivedPurchases.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "Archive is empty"), systemImage: "archivebox")
                    } description: {
                        Text(String(localized: "Purchases you keep or return will appear here."))
                    }
                } else {
                    List(archivedPurchases) { purchase in
                        NavigationLink {
                            PurchaseDetailView(purchase: purchase)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(purchase.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(outcomeLabel(for: purchase.outcome))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Text("\(purchase.useCount) \(String(localized: "uses"))")
                                    Spacer()
                                    if let costPerUse = purchase.costPerUse {
                                        Text(costPerUse, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Archive"))
        }
    }

    private func outcomeLabel(for outcome: PurchaseOutcome) -> String {
        switch outcome {
        case .active: String(localized: "Active")
        case .kept: String(localized: "Kept")
        case .returned: String(localized: "Returned")
        }
    }
}
