import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Purchase.createdAt, order: .reverse) private var purchases: [Purchase]

    private var active: [Purchase] { purchases.filter { $0.outcome == .active } }
    private var kept: [Purchase] { purchases.filter { $0.outcome == .kept } }
    private var returned: [Purchase] { purchases.filter { $0.outcome == .returned } }
    private var totalTrackedValue: Double { purchases.reduce(0) { $0 + $1.price } }
    private var totalUses: Int { purchases.reduce(0) { $0 + $1.useCount } }

    private var averageCostPerUse: Double? {
        let values = purchases.compactMap(\.costPerUse)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var bestValuePurchase: Purchase? {
        purchases
            .filter { $0.costPerUse != nil }
            .min { ($0.costPerUse ?? .greatestFiniteMagnitude) < ($1.costPerUse ?? .greatestFiniteMagnitude) }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if purchases.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "No insights yet"), systemImage: "chart.bar")
                        } description: {
                            Text(String(localized: "Track your first purchase and log a few uses to build meaningful insights."))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        summaryGrid
                        decisionSection
                        valueSection
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Insights"))
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            InsightCard(
                icon: "shippingbox",
                title: String(localized: "Tracked value"),
                value: totalTrackedValue.formatted(.currency(code: currencyCode))
            )

            InsightCard(
                icon: "hand.tap",
                title: String(localized: "Total uses"),
                value: "\(totalUses)"
            )

            InsightCard(
                icon: "eurosign.circle",
                title: String(localized: "Avg. cost / use"),
                value: averageCostPerUse?.formatted(.currency(code: currencyCode)) ?? "—"
            )

            InsightCard(
                icon: "timer",
                title: String(localized: "Active decisions"),
                value: "\(active.count)"
            )
        }
    }

    private var decisionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Your decisions"))
                .font(.title3.bold())

            HStack(spacing: 12) {
                DecisionCountCard(
                    title: String(localized: "Kept"),
                    count: kept.count,
                    systemImage: "checkmark.circle.fill"
                )

                DecisionCountCard(
                    title: String(localized: "Returned"),
                    count: returned.count,
                    systemImage: "arrow.uturn.backward.circle.fill"
                )
            }
        }
    }

    @ViewBuilder
    private var valueSection: some View {
        if let bestValuePurchase, let costPerUse = bestValuePurchase.costPerUse {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Best value so far"))
                    .font(.title3.bold())

                HStack(spacing: 14) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .frame(width: 46, height: 46)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(bestValuePurchase.name)
                            .font(.headline)
                        Text("\(bestValuePurchase.useCount) \(String(localized: "uses")) · \(costPerUse.formatted(.currency(code: currencyCode))) / \(String(localized: "use"))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
}

private struct InsightCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct DecisionCountCard: View {
    let title: String
    let count: Int
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
