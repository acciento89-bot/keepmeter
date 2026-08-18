import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showingPaywall = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

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
                        .disabled(entitlementStore.isLoading)
                    } header: {
                        Text(String(localized: "Pro"))
                    }

#if DEBUG
                    Section("StoreKit QA") {
                        LabeledContent("Product ID", value: EntitlementStore.lifetimeProductID)

                        LabeledContent("Product") {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(entitlementStore.lifetimeProduct == nil ? KMTheme.warning : KMTheme.success)
                                    .frame(width: 8, height: 8)
                                Text(entitlementStore.lifetimeProduct == nil ? "Not loaded" : "Loaded")
                            }
                        }

                        if let product = entitlementStore.lifetimeProduct {
                            LabeledContent(String(localized: "Price"), value: product.displayPrice)
                        }

                        LabeledContent("Entitlement") {
                            Text(entitlementStore.isPro ? "Pro active" : "Free")
                                .foregroundStyle(entitlementStore.isPro ? KMTheme.success : .secondary)
                        }

                        Button {
                            Task {
                                await entitlementStore.load()
                            }
                        } label: {
                            Label("Reload StoreKit product", systemImage: "arrow.clockwise")
                        }
                        .disabled(entitlementStore.isLoading)

                        Button {
                            Task {
                                await entitlementStore.refreshEntitlements()
                            }
                        } label: {
                            Label("Refresh entitlement", systemImage: "checkmark.seal")
                        }
                        .disabled(entitlementStore.isLoading)

                        Label(
                            "Local KeepMeter.storekit is attached to the Debug Run scheme.",
                            systemImage: "hammer.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
#endif

                    Section(String(localized: "Reminders")) {
                        HStack(spacing: 12) {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(String(localized: "Notification permission"))
                                        .foregroundStyle(.primary)
                                    Text(notificationStatusDetail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: notificationStatusIcon)
                                    .foregroundStyle(notificationStatusTint)
                            }

                            Spacer(minLength: 8)

                            Text(notificationStatusLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(notificationStatusTint)
                        }

                        switch notificationStatus {
                        case .notDetermined:
                            Button {
                                Task {
                                    _ = await NotificationManager.requestAuthorization()
                                    await refreshNotificationStatus()
                                }
                            } label: {
                                Label(String(localized: "Enable reminders"), systemImage: "bell.badge")
                            }

                        case .denied:
                            Button {
                                openSystemSettings()
                            } label: {
                                Label(String(localized: "Open iOS Settings"), systemImage: "gear")
                            }

                        case .authorized, .provisional, .ephemeral:
                            Label(String(localized: "Return reminders are available on this device."), systemImage: "checkmark.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                        @unknown default:
                            EmptyView()
                        }
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
            .task {
                await refreshNotificationStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await refreshNotificationStatus()
                }
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

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .notDetermined:
            String(localized: "Not asked")
        case .denied:
            String(localized: "Off")
        case .authorized:
            String(localized: "On")
        case .provisional:
            String(localized: "Provisional")
        case .ephemeral:
            String(localized: "Temporary")
        @unknown default:
            String(localized: "Unknown")
        }
    }

    private var notificationStatusDetail: String {
        switch notificationStatus {
        case .notDetermined:
            String(localized: "KeepMeter has not asked for notification permission yet.")
        case .denied:
            String(localized: "Notifications are disabled in iOS Settings.")
        case .authorized, .provisional, .ephemeral:
            String(localized: "KeepMeter can schedule return-deadline reminders.")
        @unknown default:
            String(localized: "Notification status could not be determined.")
        }
    }

    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .notDetermined:
            "bell.badge"
        case .denied:
            "bell.slash.fill"
        case .authorized, .provisional, .ephemeral:
            "bell.fill"
        @unknown default:
            "questionmark.circle"
        }
    }

    private var notificationStatusTint: Color {
        switch notificationStatus {
        case .notDetermined:
            KMTheme.warning
        case .denied:
            KMTheme.danger
        case .authorized, .provisional, .ephemeral:
            KMTheme.success
        @unknown default:
            .secondary
        }
    }

    @MainActor
    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationManager.authorizationStatus()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
