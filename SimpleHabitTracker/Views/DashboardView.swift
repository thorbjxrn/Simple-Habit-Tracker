import SwiftUI

struct DashboardView: View {
    let viewModel: HabitViewModel
    let isPremium: Bool

    var body: some View {
        TabView {
            MonthlyCalendarPanel(viewModel: viewModel)
            TrendGraphPanel(viewModel: viewModel, isPremium: isPremium)
            StatsPanel(viewModel: viewModel)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}
