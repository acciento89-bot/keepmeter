import SwiftUI

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
    }
}
