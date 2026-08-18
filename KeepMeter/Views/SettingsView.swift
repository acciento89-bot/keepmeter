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
            List {
                Section(String(localized: "Pro")) {
                    Button {
                        if !entitlementStore.isPro {
                            showingPaywall = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: entitlementStore.isPro ? "checkmark.seal.fill" : "sparkles")
                                .font(.title2)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entitlementStore.isPro ? String(localized: "Lifetime Pro unlocked") : String(localized: "KeepMeter Pro"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(entitlementStore.isPro ? String(localized: "Unlimited active purchases are enabled.") : String(localized: "One purchase. No subscription."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if !entitlementStore.isPro {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    Button(String(localized: "Restore purchases")) {
                        Task {
                            await entitlementStore.restorePurchases()
                        }
                    }
                }

                Section(String(localized: "Privacy")) {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(localized: "Local-first"))
                            Text(String(localized: "Your core purchase and usage data stays on this device. No account is required for v1."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield")
                    }
                }

                Section(String(localized: "Help")) {
                    Button(String(localized: "Show introduction again")) {
                        hasCompletedOnboarding = false
                    }
                }

                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: versionText)
                    LabeledContent(String(localized: "Developer"), value: "Kamilunavo")
                }

                if let error = entitlementStore.lastErrorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}
