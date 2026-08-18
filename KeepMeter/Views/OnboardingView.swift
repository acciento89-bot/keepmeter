import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(
            icon: "bag.badge.questionmark",
            title: String(localized: "Buy less blindly"),
            text: String(localized: "Add a purchase and keep its return deadline visible instead of forgetting it in a drawer."),
            accent: .blue
        ),
        .init(
            icon: "plus.circle.fill",
            title: String(localized: "Track real use"),
            text: String(localized: "Tap once whenever you use an item. KeepMeter turns that into usage count and cost per use."),
            accent: .indigo
        ),
        .init(
            icon: "checkmark.seal.fill",
            title: String(localized: "Decide in time"),
            text: String(localized: "Get an explainable KEEP, REVIEW or RETURN signal before the return window closes."),
            accent: .green
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "KeepMeter"))
                        .font(.headline)
                    Spacer()
                    if page < pages.count - 1 {
                        Button(String(localized: "Skip"), action: onComplete)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        card(item)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Color.primary : Color.secondary.opacity(0.25))
                            .frame(width: index == page ? 28 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack {
                        Text(page == pages.count - 1 ? String(localized: "Start tracking") : String(localized: "Continue"))
                        Spacer()
                        Image(systemName: page == pages.count - 1 ? "checkmark" : "arrow.right")
                    }
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .foregroundStyle(Color(.systemBackground))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func card(_ item: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(item.accent.opacity(0.12))
                    .frame(width: 154, height: 154)

                Image(systemName: item.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(item.accent)
            }

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(item.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let text: String
    let accent: Color
}
