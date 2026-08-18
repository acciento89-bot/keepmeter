import SwiftUI
import SwiftData

@main
struct KeepMeterApp: App {
    @StateObject private var entitlementStore = EntitlementStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(entitlementStore)
        }
        .modelContainer(for: [Purchase.self, UsageEvent.self])
    }
}
