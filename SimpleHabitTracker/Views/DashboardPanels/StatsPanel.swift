import SwiftUI

struct StatsPanel: View {
    let viewModel: HabitViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                StatCard(
                    title: "Current Streak",
                    value: "\(viewModel.currentStreak())",
                    unit: "weeks",
                    systemImage: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Best Week",
                    value: "\(viewModel.bestWeekCompletionCount())",
                    unit: "completions",
                    systemImage: "trophy.fill",
                    color: .yellow
                )

                StatCard(
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", viewModel.overallCompletionRate() * 100),
                    unit: "overall",
                    systemImage: "chart.pie.fill",
                    color: .green
                )

                StatCard(
                    title: "Total Completions",
                    value: "\(viewModel.totalCompletions())",
                    unit: "days",
                    systemImage: "checkmark.circle.fill",
                    color: .blue
                )
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
