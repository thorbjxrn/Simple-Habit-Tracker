import SwiftUI

struct OnboardingView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue
    @State private var currentPage = 0
    var onComplete: () -> Void

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)
                tutorialPage
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration using SF Symbols
            ZStack {
                // Calendar backdrop
                Image(systemName: "calendar")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(theme.accentColor.opacity(0.3))

                // Checkmark overlay
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(theme.completedColor)
                    .offset(x: 20, y: 10)
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text("Track your habits,")
                    .font(.title)
                    .fontWeight(.bold)
                Text("one week at a time")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.accentColor)
            }

            Text("A simple, focused way to build\nbetter habits every week.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 2: Tutorial

    private var tutorialPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How it works")
                .font(.title2)
                .fontWeight(.bold)

            // Tap-to-toggle cycle demonstration
            VStack(spacing: 20) {
                tutorialRow(
                    icon: "hand.tap",
                    title: "Tap to track",
                    description: "Tap each day to cycle through states"
                )

                // Visual cycle: gray -> green -> red -> gray
                HStack(spacing: 12) {
                    stateBubble(color: theme.notCompletedColor, label: "Skip")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    stateBubble(color: theme.completedColor, label: "Done")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    stateBubble(color: theme.failedColor, label: "Missed")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    stateBubble(color: theme.notCompletedColor, label: "Skip")
                }
                .padding(.vertical, 8)

                tutorialRow(
                    icon: "hand.draw",
                    title: "Swipe to navigate",
                    description: "Swipe left or right to view past weeks"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            Spacer()

            // Get Started button
            Button(action: onComplete) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(theme.accentColor)
                    )
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Components

    private func tutorialRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func stateBubble(color: Color, label: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
