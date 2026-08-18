import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(String(localized: "Active"), systemImage: "gauge.with.dots.needle.67percent")
                }

            ArchiveView()
                .tabItem {
                    Label(String(localized: "Archive"), systemImage: "archivebox")
                }
        }
    }
}
