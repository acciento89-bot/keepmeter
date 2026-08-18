import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query(sort: \Purchase.archivedAt, order: .reverse) private var purchases: [Purchase]

    private var archivedPurchases: [Purchase] {
        purchases.filter { $0.outcome != .active }
    }

    private var keptCount: Int {
        archivedPurchases.filter { $0.outcome == .kept }.count
    }

    private var returnedCount: Int {
        archivedPurchases.filter { $0.outcome == .returned }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KMBackground()

                if archivedPurchases.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            archiveSummary

                            ForEach(archivedPurchases) { purchase in
                                archiveCard(purchase)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle(String(localized: "Archive"))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KMTheme.accent.opacity(0.10))
                    .frame(width: 116, height: 116)
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 43, weight: .medium))
                    .foregroundStyle(KMTheme.accent)
            }

            VStack(spacing: 8) {
                Text(String(localized: "Archive is empty"))
                    .font(.title2.bold())
                Text(String(localized: "Purchases you keep or return will appear here."))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private var archiveSummary: some View {
        HStack(spacing: 12) {
            archiveCount(
                title: String(localized: "Kept"),
                count: keptCount,
                icon: "checkmark.circle.fill",
                tint: KMTheme.success
            )

            archiveCount(
                title: String(localized: "Returned"),
                count: returnedCount,
                icon: "arrow.uturn.backward.circle.fill",
                tint: KMTheme.danger
            )
        }
    }

    private func archiveCount(title: String, count: Int, icon: String, tint: Color) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.11))
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            .frame(width: 38, height: 38)

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
        .kmCard(radius: 18)
    }

    private func archiveCard(_ purchase: Purchase) -> some View {
        NavigationLink {
            PurchaseDetailView(purchase: purchase)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(outcomeColor(for: purchase.outcome).opacity(0.11))
                    Image(systemName: outcomeIcon(for: purchase.outcome))
                        .font(.title3.bold())
                        .foregroundStyle(outcomeColor(for: purchase.outcome))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(purchase.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(outcomeLabel(for: purchase.outcome))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(outcomeColor(for: purchase.outcome).opacity(0.10), in: Capsule())
                            .foregroundStyle(outcomeColor(for: purchase.outcome))
                    }

                    HStack(spacing: 6) {
                        Text("\(purchase.useCount) \(String(localized: "uses"))")

                        if let costPerUse = purchase.costPerUse {
                            Text("·")
                            Text(costPerUse, format: .currency(code: Locale.current.currency?.identifier ?? "EUR"))
                            Text("/ \(String(localized: "use"))")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .kmCard(radius: 20)
        }
        .buttonStyle(.plain)
    }

    private func outcomeLabel(for outcome: PurchaseOutcome) -> String {
        switch outcome {
        case .active: String(localized: "Active")
        case .kept: String(localized: "Kept")
        case .returned: String(localized: "Returned")
        }
    }

    private func outcomeColor(for outcome: PurchaseOutcome) -> Color {
        switch outcome {
        case .active: KMTheme.accent
        case .kept: KMTheme.success
        case .returned: KMTheme.danger
        }
    }

    private func outcomeIcon(for outcome: PurchaseOutcome) -> String {
        switch outcome {
        case .active: "timer"
        case .kept: "checkmark.circle.fill"
        case .returned: "arrow.uturn.backward.circle.fill"
        }
    }
}
