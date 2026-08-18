import SwiftUI
import SwiftData

@main
struct KeepMeterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Purchase.self, UsageEvent.self])
    }
}
