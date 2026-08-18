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
            ZStack {
                KMBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if purchases.isEmpty {
                            emptyState
                        } else {
                            heroCard
                            summaryGrid
                            decisionSection
                            valueSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(String(localized: "Insights"))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)

            ZStack {
                Circle()
                    .fill(KMTheme.accent.opacity(0.10))
                    .frame(width: 116, height: 116)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(KMTheme.accent)
            }

            VStack(spacing: 8) {
                Text(String(localized: "No insights yet"))
                    .font(.title2.bold())
                Text(String(localized: "Track your first purchase and log a few uses to build meaningful insights."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 330)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KMTheme.accent.opacity(0.12))
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(KMTheme.accent)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "Tracked value"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(totalTrackedValue.formatted(.currency(code: currencyCode)))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(18)
        .kmCard()
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            InsightCard(
                icon: "hand.tap.fill",
                title: String(localized: "Total uses"),
                value: "\(totalUses)",
                tint: KMTheme.accent
            )

            InsightCard(
                icon: "eurosign.circle.fill",
                title: String(localized: "Avg. cost / use"),
                value: averageCostPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                tint: KMTheme.accentSoft
            )

            InsightCard(
                icon: "hourglass",
                title: String(localized: "Active decisions"),
                value: "\(active.count)",
                tint: KMTheme.warning
            )

            InsightCard(
                icon: "checkmark.seal.fill",
                title: String(localized: "Kept"),
                value: "\(kept.count)",
                tint: KMTheme.success
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
                    systemImage: "checkmark.circle.fill",
                    tint: KMTheme.success
                )

                DecisionCountCard(
                    title: String(localized: "Returned"),
                    count: returned.count,
                    systemImage: "arrow.uturn.backward.circle.fill",
                    tint: KMTheme.danger
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(KMTheme.warning.opacity(0.12))
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundStyle(KMTheme.warning)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(bestValuePurchase.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(bestValuePurchase.useCount) \(String(localized: "uses")) · \(costPerUse.formatted(.currency(code: currencyCode))) / \(String(localized: "use"))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer()
                }
                .padding(16)
                .kmCard(radius: 20)
            }
        }
    }
}

private struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.11))
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(16)
        .kmCard(radius: 20)
    }
}

private struct DecisionCountCard: View {
    let title: String
    let count: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .kmCard(radius: 18)
    }
}
