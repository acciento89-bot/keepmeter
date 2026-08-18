import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showingPaywall = false

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KMBackground()

                List {
                    Section {
                        proCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        Button {
                            Task {
                                await entitlementStore.restorePurchases()
                            }
                        } label: {
                            Label(String(localized: "Restore purchases"), systemImage: "arrow.clockwise.circle")
                        }
                    } header: {
                        Text(String(localized: "Pro"))
                    }

                    Section(String(localized: "Privacy")) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(String(localized: "Local-first"))
                                    .foregroundStyle(.primary)
                                Text(String(localized: "Your core purchase and usage data stays on this device. No account is required for v1."))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(KMTheme.success)
                        }
                    }

                    Section(String(localized: "Help")) {
                        Button {
                            hasCompletedOnboarding = false
                        } label: {
                            Label(String(localized: "Show introduction again"), systemImage: "sparkles.rectangle.stack")
                        }
                    }

                    Section(String(localized: "About")) {
                        LabeledContent(String(localized: "Version"), value: versionText)
                        LabeledContent(String(localized: "Developer"), value: "Kamilunavo")
                    }

                    if let error = entitlementStore.lastErrorMessage {
                        Section {
                            Label {
                                Text(error)
                                    .font(.footnote)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(KMTheme.warning)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listSectionSpacing(18)
            }
            .navigationTitle(String(localized: "Settings"))
            .tint(KMTheme.accent)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .tint(KMTheme.accent)
            }
        }
    }

    private var proCard: some View {
        Button {
            if !entitlementStore.isPro {
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                    Image(systemName: entitlementStore.isPro ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 26, weight: .semibold))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entitlementStore.isPro ? String(localized: "Lifetime Pro unlocked") : String(localized: "KeepMeter Pro"))
                        .font(.headline)

                    Text(entitlementStore.isPro ? String(localized: "Unlimited active purchases are enabled.") : String(localized: "One purchase. No subscription."))
                        .font(.subheadline)
                        .opacity(0.84)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                if !entitlementStore.isPro {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .opacity(0.75)
                }
            }
            .padding(17)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: entitlementStore.isPro
                        ? [KMTheme.success, KMTheme.success.opacity(0.78)]
                        : [KMTheme.accent, KMTheme.accentSoft],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: (entitlementStore.isPro ? KMTheme.success : KMTheme.accent).opacity(0.18), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
