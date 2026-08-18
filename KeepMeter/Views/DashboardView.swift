import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Purchase.returnDeadline) private var purchases: [Purchase]
    @State private var showingAddPurchase = false

    private var activePurchases: [Purchase] {
        purchases.filter { $0.outcome == .active }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activePurchases.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "No active purchases"), systemImage: "bag")
                    } description: {
                        Text(String(localized: "Add a recent purchase and KeepMeter will help you decide before the return window closes."))
                    } actions: {
                        Button(String(localized: "Add purchase")) {
                            showingAddPurchase = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(activePurchases) { purchase in
                                PurchaseCardView(purchase: purchase) {
                                    logUse(for: purchase)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(String(localized: "KeepMeter"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPurchase = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "Add purchase"))
                }
            }
            .sheet(isPresented: $showingAddPurchase) {
                AddPurchaseView()
            }
        }
    }

    private func logUse(for purchase: Purchase) {
        let event = UsageEvent()
        modelContext.insert(event)
        purchase.usageEvents.append(event)
        try? modelContext.save()
    }
}

private struct PurchaseCardView: View {
    let purchase: Purchase
    let onUse: () -> Void

    private var snapshot: DecisionSnapshot {
        DecisionEngine.evaluate(purchase)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                PurchaseDetailView(purchase: purchase)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(purchase.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if !purchase.merchant.isEmpty {
                                Text(purchase.merchant)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        DecisionBadge(status: snapshot.status)
                    }

                    HStack(spacing: 18) {
                        MetricLabel(
                            title: String(localized: "Uses"),
                            value: "\(purchase.useCount)"
                        )

                        MetricLabel(
                            title: String(localized: "Cost / use"),
                            value: purchase.costPerUse.map { $0.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")) } ?? "—"
                        )

                        MetricLabel(
                            title: String(localized: "Days left"),
                            value: "\(max(snapshot.daysRemaining, 0))"
                        )
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: onUse) {
                Label(String(localized: "Used it"), systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct MetricLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

struct DecisionBadge: View {
    let status: DecisionStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
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
        case .keep: .green
        case .review: .orange
        case .returnCandidate: .red
        }
    }
}
