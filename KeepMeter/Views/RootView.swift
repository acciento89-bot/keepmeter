import SwiftUI
import SwiftData

enum KMTheme {
    static let accent = Color(red: 0.19, green: 0.42, blue: 0.96)
    static let accentSoft = Color(red: 0.39, green: 0.63, blue: 1.00)
    static let success = Color(red: 0.13, green: 0.66, blue: 0.43)
    static let warning = Color(red: 0.95, green: 0.58, blue: 0.12)
    static let danger = Color(red: 0.92, green: 0.27, blue: 0.31)
    static let cardRadius: CGFloat = 24

    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                accent.opacity(0.055),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct KMBackground: View {
    var body: some View {
        KMTheme.appBackground
            .ignoresSafeArea()
    }
}

extension View {
    func kmCard(radius: CGFloat = KMTheme.cardRadius) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.8)
            }
            .shadow(color: Color.black.opacity(0.045), radius: 12, y: 6)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label(String(localized: "Active"), systemImage: "gauge.with.dots.needle.67percent")
                        }

                    InsightsView()
                        .tabItem {
                            Label(String(localized: "Insights"), systemImage: "chart.bar.xaxis")
                        }

                    ArchiveView()
                        .tabItem {
                            Label(String(localized: "Archive"), systemImage: "archivebox")
                        }

                    SettingsView()
                        .tabItem {
                            Label(String(localized: "Settings"), systemImage: "gearshape")
                        }
                }
                .tint(KMTheme.accent)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .task {
            #if DEBUG
            runRuntimeSmokeHooksIfRequested()
            #endif
        }
    }

    #if DEBUG
    private static let runtimeHeadphonesID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let runtimeBackpackID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let runtimePersistenceSentinel = "keepmeter-runtime-persistence-ok.txt"
    private static let runtimeLaunchSentinel = "keepmeter-runtime-launch-ok.txt"
    private static let runtimeLaunchTokenPrefix = "--keepMeterRuntimeLaunchToken="

    private func runRuntimeSmokeHooksIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--keepMeterRuntimeLaunchProbe") {
            writeRuntimeLaunchSentinel(arguments: arguments)
        }

        if arguments.contains("--keepMeterRuntimeSeed") {
            seedRuntimeSmokePurchases()
        }

        if arguments.contains("--keepMeterRuntimeProbe") {
            writeRuntimePersistenceSentinelIfValid()
        }
    }

    private func writeRuntimeLaunchSentinel(arguments: [String]) {
        guard
            let tokenArgument = arguments.first(where: { $0.hasPrefix(Self.runtimeLaunchTokenPrefix) }),
            !tokenArgument.dropFirst(Self.runtimeLaunchTokenPrefix.count).isEmpty
        else {
            assertionFailure("KeepMeter runtime launch probe is missing its token")
            return
        }

        let token = String(tokenArgument.dropFirst(Self.runtimeLaunchTokenPrefix.count))

        do {
            let sentinelURL = try runtimeSentinelURL(named: Self.runtimeLaunchSentinel)
            try token.write(to: sentinelURL, atomically: true, encoding: .utf8)
            print("KeepMeter runtime smoke: launch probe reached SwiftUI root")
        } catch {
            assertionFailure("KeepMeter runtime launch probe failed: \(error)")
        }
    }

    private func seedRuntimeSmokePurchases() {
        do {
            try removeRuntimeSentinelIfPresent(named: Self.runtimePersistenceSentinel)

            let purchases = try modelContext.fetch(FetchDescriptor<Purchase>())
            let existingIDs = Set(purchases.map(\.id))
            let calendar = Calendar.current
            let reference = calendar.startOfDay(for: .now)

            if !existingIDs.contains(Self.runtimeHeadphonesID) {
                let usageOffsets = [-6, -4, -2, -1]
                let events = usageOffsets.compactMap { offset -> UsageEvent? in
                    guard let date = calendar.date(byAdding: .day, value: offset, to: reference) else { return nil }
                    return UsageEvent(timestamp: date)
                }

                let headphones = Purchase(
                    id: Self.runtimeHeadphonesID,
                    name: "Studio Headphones",
                    merchant: "Audio Store",
                    price: 349,
                    purchaseDate: calendar.date(byAdding: .day, value: -7, to: reference) ?? reference,
                    returnDeadline: calendar.date(byAdding: .day, value: 7, to: reference) ?? reference,
                    usageEvents: events
                )
                modelContext.insert(headphones)
            }

            if !existingIDs.contains(Self.runtimeBackpackID) {
                let backpack = Purchase(
                    id: Self.runtimeBackpackID,
                    name: "Travel Backpack",
                    merchant: "City Shop",
                    price: 149,
                    purchaseDate: calendar.date(byAdding: .day, value: -10, to: reference) ?? reference,
                    returnDeadline: calendar.date(byAdding: .day, value: 2, to: reference) ?? reference
                )
                modelContext.insert(backpack)
            }

            try modelContext.save()
            print("KeepMeter runtime smoke: seeded deterministic purchases")
        } catch {
            assertionFailure("KeepMeter runtime smoke seed failed: \(error)")
        }
    }

    private func writeRuntimePersistenceSentinelIfValid() {
        do {
            let purchases = try modelContext.fetch(FetchDescriptor<Purchase>())
            guard
                let headphones = purchases.first(where: { $0.id == Self.runtimeHeadphonesID }),
                let backpack = purchases.first(where: { $0.id == Self.runtimeBackpackID }),
                headphones.outcome == .active,
                headphones.useCount == 4,
                abs(headphones.price - 349) < 0.001,
                backpack.outcome == .active,
                backpack.useCount == 0,
                abs(backpack.price - 149) < 0.001,
                DecisionEngine.evaluate(headphones).status == .keep,
                DecisionEngine.evaluate(backpack).status == .returnCandidate
            else {
                print("KeepMeter runtime smoke: persistence probe did not find expected purchases")
                return
            }

            let sentinelURL = try runtimeSentinelURL(named: Self.runtimePersistenceSentinel)
            try "ok\n".write(to: sentinelURL, atomically: true, encoding: .utf8)
            print("KeepMeter runtime smoke: persisted purchases verified after relaunch")
        } catch {
            assertionFailure("KeepMeter runtime smoke persistence probe failed: \(error)")
        }
    }

    private func removeRuntimeSentinelIfPresent(named name: String) throws {
        let url = try runtimeSentinelURL(named: name)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func runtimeSentinelURL(named name: String) throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return documents.appendingPathComponent(name)
    }
    #endif
}
