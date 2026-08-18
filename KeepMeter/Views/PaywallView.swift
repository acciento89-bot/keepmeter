import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementStore: EntitlementStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 58, weight: .semibold))

                VStack(spacing: 10) {
                    Text(String(localized: "KeepMeter Pro"))
                        .font(.largeTitle.bold())

                    Text(String(localized: "Track more than five active purchases with a one-time Lifetime Pro unlock."))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label(String(localized: "Unlimited active purchases"), systemImage: "infinity")
                    Label(String(localized: "No subscription"), systemImage: "checkmark.seal")
                    Label(String(localized: "Future Pro features included"), systemImage: "sparkles")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    Task {
                        await entitlementStore.purchaseLifetime()
                        if entitlementStore.isPro {
                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if entitlementStore.isLoading {
                            ProgressView()
                        } else if let product = entitlementStore.lifetimeProduct {
                            Text(String(localized: "Unlock Lifetime Pro — \(product.displayPrice)"))
                        } else {
                            Text(String(localized: "Load Lifetime Pro"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(String(localized: "Restore purchases")) {
                    Task {
                        await entitlementStore.restorePurchases()
                        if entitlementStore.isPro {
                            dismiss()
                        }
                    }
                }
                .font(.footnote)

                if let error = entitlementStore.lastErrorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
