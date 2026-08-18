import SwiftUI

struct RootView: View {
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
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}
