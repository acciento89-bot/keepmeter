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

    private var statusColor: Color {
        switch snapshot.status {
        case .keep: KMTheme.success
        case .review: KMTheme.warning
        case .returnCandidate: KMTheme.danger
        }
    }

    var body: some View {
        ZStack {
            KMBackground()

            ScrollView {
                VStack(spacing: 16) {
                    decisionHero
                    useAction
                    purchaseInformation

                    if !purchase.usageEvents.isEmpty {
                        recentUses
                    }

                    finalDecision
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(purchase.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var decisionHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(statusColor.opacity(0.12))

                    Image(systemName: statusIcon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        DecisionBadge(status: snapshot.status)
                        Spacer()
                    }

                    Text(purchase.price, format: .currency(code: currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
            }

            Text(reasonText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                DetailMetric(
                    title: String(localized: "Uses"),
                    value: "\(purchase.useCount)",
                    icon: "hand.tap"
                )

                divider

                DetailMetric(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                    icon: "eurosign.circle"
                )

                divider

                DetailMetric(
                    title: String(localized: "Days left"),
                    value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : String(localized: "Expired"),
                    icon: "hourglass"
                )
            }
        }
        .padding(18)
        .kmCard()
    }

    private var useAction: some View {
        Button {
            logUse()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "Log a use"))
                        .font(.headline)
                    Text(String(localized: "One tap updates the real cost per use."))
                        .font(.caption)
                        .opacity(0.82)
                }

                Spacer()
                Image(systemName: "hand.tap.fill")
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 68)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [KMTheme.accent, KMTheme.accentSoft],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .shadow(color: KMTheme.accent.opacity(0.18), radius: 12, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var purchaseInformation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Purchase details"))
                .font(.headline)

            infoRow(
                icon: "calendar",
                title: String(localized: "Purchased"),
                value: purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted)
            )

            infoRow(
                icon: "calendar.badge.clock",
                title: String(localized: "Return by"),
                value: purchase.returnDeadline.formatted(date: .abbreviated, time: .omitted)
            )

            if !purchase.merchant.isEmpty {
                infoRow(
                    icon: "storefront",
                    title: String(localized: "Merchant"),
                    value: purchase.merchant
                )
            }
        }
        .padding(18)
        .kmCard()
    }

    private var recentUses: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(String(localized: "Recent uses"))
                    .font(.headline)
                Spacer()
                Text("\(purchase.useCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(KMTheme.accent.opacity(0.10), in: Capsule())
                    .foregroundStyle(KMTheme.accent)
            }

            ForEach(Array(purchase.usageEvents.sorted { $0.timestamp > $1.timestamp }.prefix(5).enumerated()), id: \.element.id) { index, event in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(KMTheme.success)

                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)

                    Spacer()
                }

                if index < min(purchase.usageEvents.count, 5) - 1 {
                    Divider()
                        .padding(.leading, 32)
                }
            }
        }
        .padding(18)
        .kmCard()
    }

    private var finalDecision: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Your final decision"))
                    .font(.headline)
                Text(String(localized: "KeepMeter gives you a signal. You stay in control."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                finish(as: .kept)
            } label: {
                Label(String(localized: "Keep purchase"), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(KMTheme.success)

            Button {
                finish(as: .returned)
            } label: {
                Label(String(localized: "Mark as returned"), systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.bordered)
            .tint(KMTheme.danger)
        }
        .padding(18)
        .kmCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 1, height: 46)
            .padding(.horizontal, 8)
    }

    private var statusIcon: String {
        switch snapshot.status {
        case .keep: "checkmark.seal.fill"
        case .review: "eye.fill"
        case .returnCandidate: "arrow.uturn.backward.circle.fill"
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(KMTheme.accent)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
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
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
