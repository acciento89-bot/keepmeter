import SwiftUI
import SwiftData
import UIKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @Query(sort: \Purchase.returnDeadline) private var purchases: [Purchase]

    @State private var showingAddPurchase = false
    @State private var showingPaywall = false

    private let freeActivePurchaseLimit = 5

    private var activePurchases: [Purchase] {
        purchases.filter { $0.outcome == .active }
    }

    private var urgentCount: Int {
        activePurchases.filter { $0.daysRemaining() <= 3 }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KMBackground()

                if activePurchases.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            dashboardHeader

                            if !entitlementStore.isPro && activePurchases.count >= freeActivePurchaseLimit {
                                freeLimitBanner
                            }

                            ForEach(activePurchases) { purchase in
                                PurchaseCardView(purchase: purchase) {
                                    logUse(for: purchase)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle(String(localized: "KeepMeter"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentAddPurchase()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(KMTheme.accent.opacity(0.12), in: Circle())
                    }
                    .foregroundStyle(KMTheme.accent)
                    .accessibilityLabel(String(localized: "Add purchase"))
                }
            }
            .sheet(isPresented: $showingAddPurchase) {
                AddPurchaseView()
                    .tint(KMTheme.accent)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .tint(KMTheme.accent)
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(KMTheme.accent.opacity(0.12))

                Image(systemName: urgentCount > 0 ? "hourglass.bottomhalf.filled" : "checkmark.seal.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(urgentCount > 0 ? KMTheme.warning : KMTheme.accent)
            }
            .frame(width: 58, height: 58)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Decision dashboard"))
                    .font(.headline)

                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .kmCard()
        .accessibilityElement(children: .combine)
    }

    private var headerSubtitle: String {
        if urgentCount > 0 {
            return String(
                format: NSLocalizedString(
                    "dashboard.urgentCount",
                    comment: "Number of purchases that need attention within three days; %ld is the count"
                ),
                locale: Locale.current,
                urgentCount
            )
        }
        return String(localized: "Everything is under control. Keep logging real usage.")
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KMTheme.accent.opacity(0.10))
                    .frame(width: 128, height: 128)

                Circle()
                    .stroke(KMTheme.accent.opacity(0.16), lineWidth: 1)
                    .frame(width: 104, height: 104)

                Image(systemName: "bag.badge.questionmark")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(KMTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(String(localized: "No active purchases"))
                    .font(.title2.bold())

                Text(String(localized: "Add a recent purchase and KeepMeter will help you decide before the return window closes."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 330)
            }

            Button {
                presentAddPurchase()
            } label: {
                Label(String(localized: "Add purchase"), systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(KMTheme.accent)

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private var freeLimitBanner: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(KMTheme.accent.opacity(0.12))
                    Image(systemName: "sparkles")
                        .foregroundStyle(KMTheme.accent)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "Free limit reached"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(String(localized: "Lifetime Pro unlocks unlimited active purchases."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(15)
            .kmCard(radius: 20)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func presentAddPurchase() {
        if !entitlementStore.isPro && activePurchases.count >= freeActivePurchaseLimit {
            showingPaywall = true
        } else {
            showingAddPurchase = true
        }
    }

    private func logUse(for purchase: Purchase) {
        guard purchase.outcome == .active else { return }

        let event = UsageEvent()
        modelContext.insert(event)
        purchase.usageEvents.append(event)
        try? modelContext.save()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

private struct PurchaseCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let purchase: Purchase
    let onUse: () -> Void

    private var snapshot: DecisionSnapshot {
        DecisionEngine.evaluate(purchase)
    }

    private var progress: Double {
        purchase.returnWindowElapsedRatio()
    }

    private var statusColor: Color {
        switch snapshot.status {
        case .keep: KMTheme.success
        case .review: KMTheme.warning
        case .returnCandidate: KMTheme.danger
        }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink {
                PurchaseDetailView(purchase: purchase)
            } label: {
                VStack(alignment: .leading, spacing: 15) {
                    purchaseHeader
                    metrics

                    VStack(spacing: 6) {
                        HStack {
                            Text(String(localized: "Return window"))
                            Spacer()
                            Text(purchase.returnDeadline.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.07))
                                Capsule()
                                    .fill(statusColor.opacity(0.75))
                                    .frame(width: max(8, geometry.size.width * min(max(progress, 0), 1)))
                            }
                        }
                        .frame(height: 6)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(String(localized: "Return window"))
                        .accessibilityValue(progress.formatted(.percent.precision(.fractionLength(0))))
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            Divider()
                .opacity(0.5)

            Button(action: onUse) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "Used it"))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KMTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .kmCard()
    }

    @ViewBuilder
    private var purchaseHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    statusIconView
                    purchaseIdentity
                }
                DecisionBadge(status: snapshot.status)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                statusIconView
                purchaseIdentity
                Spacer(minLength: 6)
                DecisionBadge(status: snapshot.status)
            }
        }
    }

    private var statusIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(statusColor.opacity(0.11))

            Image(systemName: statusIcon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(statusColor)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }

    private var purchaseIdentity: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(purchase.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)

            Text(purchase.merchant.isEmpty ? purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted) : purchase.merchant)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                MetricLabel(title: String(localized: "Uses"), value: "\(purchase.useCount)")
                Divider()
                MetricLabel(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—"
                )
                Divider()
                MetricLabel(
                    title: String(localized: "Days left"),
                    value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : "—"
                )
            }
        } else {
            HStack(spacing: 0) {
                MetricLabel(title: String(localized: "Uses"), value: "\(purchase.useCount)")
                metricDivider
                MetricLabel(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—"
                )
                metricDivider
                MetricLabel(
                    title: String(localized: "Days left"),
                    value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : "—"
                )
            }
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 1, height: 32)
            .padding(.horizontal, 14)
    }

    private var statusIcon: String {
        switch snapshot.status {
        case .keep: "checkmark.seal.fill"
        case .review: "eye.fill"
        case .returnCandidate: "arrow.uturn.backward.circle.fill"
        }
    }
}

private struct MetricLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct DecisionBadge: View {
    let status: DecisionStatus

    var body: some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .tracking(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(tint.opacity(0.18), lineWidth: 0.8)
            }
            .foregroundStyle(tint)
            .accessibilityLabel(label)
    }

    private var label: String {
        switch status {
        case .keep: String(localized: "KEEP")
        case .review: String(localized: "REVIEW")
        case .returnCandidate: String(localized: "RETURN?")
        }
    }

    private var tint: Color {
        switch status {
        case .keep: KMTheme.success
        case .review: KMTheme.warning
        case .returnCandidate: KMTheme.danger
        }
    }
}
