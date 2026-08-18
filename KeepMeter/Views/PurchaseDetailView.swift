import SwiftUI
import SwiftData

struct PurchaseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let purchase: Purchase

    private var snapshot: DecisionSnapshot {
        DecisionEngine.evaluate(purchase)
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        DecisionBadge(status: snapshot.status)
                        Spacer()
                        Text(purchase.price, format: .currency(code: currencyCode))
                            .font(.headline)
                    }

                    Text(reasonText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 24) {
                        DetailMetric(title: String(localized: "Uses"), value: "\(purchase.useCount)")
                        DetailMetric(
                            title: String(localized: "Cost / use"),
                            value: purchase.costPerUse.map { $0.formatted(.currency(code: currencyCode)) } ?? "—"
                        )
                        DetailMetric(
                            title: String(localized: "Days left"),
                            value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : String(localized: "Expired")
                        )
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                Button {
                    logUse()
                } label: {
                    Label(String(localized: "Log a use"), systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
            }

            Section(String(localized: "Purchase details")) {
                LabeledContent(String(localized: "Purchased"), value: purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent(String(localized: "Return by"), value: purchase.returnDeadline.formatted(date: .abbreviated, time: .omitted))

                if !purchase.merchant.isEmpty {
                    LabeledContent(String(localized: "Merchant"), value: purchase.merchant)
                }
            }

            if !purchase.usageEvents.isEmpty {
                Section(String(localized: "Recent uses")) {
                    ForEach(purchase.usageEvents.sorted { $0.timestamp > $1.timestamp }.prefix(10)) { event in
                        Label(
                            event.timestamp.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "checkmark.circle"
                        )
                    }
                }
            }

            Section(String(localized: "Decision")) {
                Button {
                    finish(as: .kept)
                } label: {
                    Label(String(localized: "Keep purchase"), systemImage: "checkmark.circle.fill")
                }

                Button(role: .destructive) {
                    finish(as: .returned)
                } label: {
                    Label(String(localized: "Mark as returned"), systemImage: "arrow.uturn.backward.circle.fill")
                }
            }
        }
        .navigationTitle(purchase.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reasonText: String {
        switch snapshot.reason {
        case .deadlinePassed:
            return String(localized: "The return date you entered has passed. Review the purchase and merchant policy manually.")
        case .unusedUrgent:
            return String(localized: "You have not logged any use and the return window is almost over. This is a strong signal to decide now.")
        case .lightlyUsedUrgent:
            return String(localized: "The item has barely been used and the return deadline is close. Review whether it is earning its place.")
        case .unusedLateWindow:
            return String(localized: "Most of the return window has passed without a logged use. It may be time to reconsider the purchase.")
        case .repeatedUse:
            return String(localized: "You have used this purchase repeatedly. That is a positive signal, but the final decision is yours.")
        case .earlyWindow:
            return String(localized: "It is still early in the return window. Use the item normally and KeepMeter will build a clearer signal.")
        case .needsMoreSignal:
            return String(localized: "There is not enough usage evidence yet for a strong signal. Keep tracking before the deadline.")
        }
    }

    private func logUse() {
        let event = UsageEvent()
        modelContext.insert(event)
        purchase.usageEvents.append(event)
        try? modelContext.save()
    }

    private func finish(as outcome: PurchaseOutcome) {
        purchase.outcome = outcome
        purchase.archivedAt = .now
        NotificationManager.cancelReturnReminders(for: purchase)
        try? modelContext.save()
        dismiss()
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}
