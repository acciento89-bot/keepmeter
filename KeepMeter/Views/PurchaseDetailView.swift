import SwiftUI
import SwiftData

struct PurchaseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let purchase: Purchase

    private var isActive: Bool {
        purchase.outcome == .active
    }

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

    private var outcomeColor: Color {
        switch purchase.outcome {
        case .active: KMTheme.accent
        case .kept: KMTheme.success
        case .returned: KMTheme.danger
        }
    }

    var body: some View {
        ZStack {
            KMBackground()

            ScrollView {
                VStack(spacing: 16) {
                    decisionHero

                    if isActive {
                        useAction
                    }

                    purchaseInformation

                    if !purchase.usageEvents.isEmpty {
                        recentUses
                    }

                    if isActive {
                        finalDecision
                    }
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

    @ViewBuilder
    private var decisionHero: some View {
        if isActive {
            activeDecisionHero
        } else {
            archivedDecisionHero
        }
    }

    private var activeDecisionHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                heroIcon(systemName: statusIcon, tint: statusColor)

                VStack(alignment: .leading, spacing: 6) {
                    DecisionBadge(status: snapshot.status)

                    Text(purchase.price, format: .currency(code: currencyCode))
                        .font(.title.bold())
                        .monospacedDigit()
                }
            }

            Text(reasonText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            activeMetrics
        }
        .padding(18)
        .kmCard()
    }

    private var archivedDecisionHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                heroIcon(systemName: outcomeIcon, tint: outcomeColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text(outcomeLabel)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(outcomeColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(outcomeColor)

                    Text(purchase.price, format: .currency(code: currencyCode))
                        .font(.title.bold())
                        .monospacedDigit()
                }
            }

            if let archivedAt = purchase.archivedAt {
                Text(archivedAt.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            archivedMetrics
        }
        .padding(18)
        .kmCard()
        .accessibilityElement(children: .combine)
    }

    private func heroIcon(systemName: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))

            Image(systemName: systemName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 66, height: 66)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var activeMetrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                detailMetric(title: String(localized: "Uses"), value: "\(purchase.useCount)", icon: "hand.tap")
                Divider()
                detailMetric(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                    icon: "eurosign.circle"
                )
                Divider()
                detailMetric(
                    title: String(localized: "Days left"),
                    value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : String(localized: "Expired"),
                    icon: "hourglass"
                )
            }
        } else {
            HStack(spacing: 0) {
                detailMetric(title: String(localized: "Uses"), value: "\(purchase.useCount)", icon: "hand.tap")
                divider
                detailMetric(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                    icon: "eurosign.circle"
                )
                divider
                detailMetric(
                    title: String(localized: "Days left"),
                    value: snapshot.daysRemaining >= 0 ? "\(snapshot.daysRemaining)" : String(localized: "Expired"),
                    icon: "hourglass"
                )
            }
        }
    }

    @ViewBuilder
    private var archivedMetrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                detailMetric(title: String(localized: "Uses"), value: "\(purchase.useCount)", icon: "hand.tap")
                Divider()
                detailMetric(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                    icon: "eurosign.circle"
                )
            }
        } else {
            HStack(spacing: 0) {
                detailMetric(title: String(localized: "Uses"), value: "\(purchase.useCount)", icon: "hand.tap")
                divider
                detailMetric(
                    title: String(localized: "Cost / use"),
                    value: purchase.costPerUse?.formatted(.currency(code: currencyCode)) ?? "—",
                    icon: "eurosign.circle"
                )
            }
        }
    }

    private func detailMetric(title: String, value: String, icon: String) -> some View {
        DetailMetric(title: title, value: value, icon: icon)
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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "Log a use"))
                        .font(.headline)
                    Text(String(localized: "One tap updates the real cost per use."))
                        .font(.caption)
                        .opacity(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "hand.tap.fill")
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .padding(16)
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
                        .accessibilityHidden(true)

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
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(KMTheme.success)

            Button {
                finish(as: .returned)
            } label: {
                Label(String(localized: "Mark as returned"), systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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

    private var outcomeIcon: String {
        switch purchase.outcome {
        case .active: "timer"
        case .kept: "checkmark.circle.fill"
        case .returned: "arrow.uturn.backward.circle.fill"
        }
    }

    private var outcomeLabel: String {
        switch purchase.outcome {
        case .active: String(localized: "Active")
        case .kept: String(localized: "Kept")
        case .returned: String(localized: "Returned")
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(KMTheme.accent)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.trailing)
            }
            .accessibilityElement(children: .combine)
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
        guard purchase.outcome == .active else { return }

        let event = UsageEvent()
        modelContext.insert(event)
        purchase.usageEvents.append(event)
        try? modelContext.save()
    }

    private func finish(as outcome: PurchaseOutcome) {
        guard purchase.outcome == .active else { return }

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
                .accessibilityHidden(true)
            Text(value)
                .font(.headline)
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
