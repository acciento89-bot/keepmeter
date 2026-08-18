import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var entitlementStore: EntitlementStore

    var body: some View {
        NavigationStack {
            ZStack {
                KMBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        hero
                        benefits
                        purchaseSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
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

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(KMTheme.accent.opacity(0.10))
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 108 : 142, height: dynamicTypeSize.isAccessibilitySize ? 108 : 142)

                Circle()
                    .stroke(KMTheme.accent.opacity(0.16), lineWidth: 1)
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 88 : 116, height: dynamicTypeSize.isAccessibilitySize ? 88 : 116)

                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 40 : 54, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(KMTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(String(localized: "KeepMeter Pro"))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(String(localized: "Track more than five active purchases with a one-time Lifetime Pro unlock."))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 350)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(String(localized: "One purchase. No subscription."))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KMTheme.success)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(KMTheme.success.opacity(0.10), in: Capsule())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var benefits: some View {
        VStack(spacing: 0) {
            benefitRow(
                icon: "infinity",
                title: String(localized: "Unlimited active purchases"),
                tint: KMTheme.accent
            )

            Divider().padding(.leading, 52)

            benefitRow(
                icon: "checkmark.seal.fill",
                title: String(localized: "No subscription"),
                tint: KMTheme.success
            )

            Divider().padding(.leading, 52)

            benefitRow(
                icon: "lock.shield.fill",
                title: String(localized: "Local-first"),
                tint: KMTheme.accent
            )
        }
        .padding(.horizontal, 16)
        .kmCard()
    }

    private var purchaseSection: some View {
        VStack(spacing: 14) {
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
                            .tint(.white)
                    } else if let product = entitlementStore.lifetimeProduct {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(spacing: 5) {
                                Text(String(localized: "Unlock Lifetime Pro"))
                                Text(product.displayPrice)
                                    .monospacedDigit()
                            }
                        } else {
                            HStack {
                                Text(String(localized: "Unlock Lifetime Pro"))
                                Spacer()
                                Text(product.displayPrice)
                                    .monospacedDigit()
                            }
                        }
                    } else {
                        HStack {
                            Text(String(localized: "Load Lifetime Pro"))
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [KMTheme.accent, KMTheme.accentSoft],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: KMTheme.accent.opacity(0.20), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(entitlementStore.isLoading)

            Button(String(localized: "Restore purchases")) {
                Task {
                    await entitlementStore.restorePurchases()
                    if entitlementStore.isPro {
                        dismiss()
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(KMTheme.accent)
            .disabled(entitlementStore.isLoading)

            if let error = entitlementStore.lastErrorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(KMTheme.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private func benefitRow(icon: String, title: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(0.11))
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}
