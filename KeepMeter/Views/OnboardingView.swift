import SwiftUI

struct OnboardingView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onComplete: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(
            icon: "bag.badge.questionmark",
            title: String(localized: "Buy less blindly"),
            text: String(localized: "Add a purchase and keep its return deadline visible instead of forgetting it in a drawer."),
            accent: KMTheme.accent
        ),
        .init(
            icon: "hand.tap.fill",
            title: String(localized: "Track real use"),
            text: String(localized: "Tap once whenever you use an item. KeepMeter turns that into usage count and cost per use."),
            accent: KMTheme.accentSoft
        ),
        .init(
            icon: "checkmark.seal.fill",
            title: String(localized: "Decide in time"),
            text: String(localized: "Get an explainable KEEP, REVIEW or RETURN signal before the return window closes."),
            accent: KMTheme.success
        )
    ]

    var body: some View {
        ZStack {
            KMBackground()

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(KMTheme.accent)
                            Image(systemName: "gauge.with.dots.needle.67percent")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(width: 32, height: 32)
                        .accessibilityHidden(true)

                        Text(String(localized: "KeepMeter"))
                            .font(.headline)
                    }

                    Spacer(minLength: 8)

                    if page < pages.count - 1 {
                        Button(String(localized: "Skip"), action: onComplete)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        onboardingCard(item)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? KMTheme.accent : Color.secondary.opacity(0.20))
                            .frame(width: index == page ? 30 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                    }
                }
                .padding(.bottom, 22)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(page + 1) / \(pages.count)")

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            page += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack {
                        Text(page == pages.count - 1 ? String(localized: "Start tracking") : String(localized: "Continue"))
                        Spacer()
                        Image(systemName: page == pages.count - 1 ? "checkmark" : "arrow.right")
                            .accessibilityHidden(true)
                    }
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [KMTheme.accent, KMTheme.accentSoft],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: KMTheme.accent.opacity(0.20), radius: 14, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func onboardingCard(_ item: OnboardingPage) -> some View {
        VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 16 : 26) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 6 : 18)

            ZStack {
                RoundedRectangle(cornerRadius: dynamicTypeSize.isAccessibilitySize ? 28 : 38, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? 170 : 280)
                    .overlay {
                        RoundedRectangle(cornerRadius: dynamicTypeSize.isAccessibilitySize ? 28 : 38, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.8)
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)

                Circle()
                    .fill(item.accent.opacity(0.12))
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 104 : 158,
                        height: dynamicTypeSize.isAccessibilitySize ? 104 : 158
                    )

                Circle()
                    .stroke(item.accent.opacity(0.15), lineWidth: 1)
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? 84 : 128,
                        height: dynamicTypeSize.isAccessibilitySize ? 84 : 128
                    )

                Image(systemName: item.icon)
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 38 : 58, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 340)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let text: String
    let accent: Color
}
