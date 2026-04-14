import SwiftUI

struct DashboardView: View {
    let viewModel: HabitViewModel
    let isPremium: Bool

    private var hasAnyData: Bool {
        viewModel.totalCompletions() > 0
    }

    var body: some View {
        if hasAnyData {
            TabView {
                MonthlyCalendarPanel(viewModel: viewModel)
                TrendGraphPanel(viewModel: viewModel, isPremium: isPremium)
                StatsPanel(viewModel: viewModel)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        } else {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Your Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Start tracking habits and your\nmonthly overview, trends, and stats\nwill appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
