import SwiftUI
import SwiftData

struct TrendGraphPanel: View {
    let viewModel: HabitViewModel
    let isPremium: Bool
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private var weeksToShow: Int {
        isPremium ? 16 : 4
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Activity")
                .font(.title3)
                .fontWeight(.bold)

            if habits.isEmpty {
                Spacer()
                Text("Add habits to see your activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                heatMapView
                legend
                if !isPremium {
                    Text("Upgrade for full history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Heat Map

    private var heatMapView: some View {
        let data = heatMapData

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 3) {
                // Week header row
                HStack(spacing: 3) {
                    Color.clear.frame(width: 60, height: 12) // spacer for habit names
                    ForEach(data.weeks, id: \.self) { weekStart in
                        Text(weekLabel(for: weekStart))
                            .font(.system(size: 7))
                            .foregroundStyle(.tertiary)
                            .frame(width: 14, height: 12)
                    }
                }

                // One row per habit
                ForEach(habits) { habit in
                    HStack(spacing: 3) {
                        Text(habit.name)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                            .lineLimit(1)

                        ForEach(data.weeks, id: \.self) { weekStart in
                            let count = completionCount(habit: habit, weekStart: weekStart)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(count: count))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
            ForEach(0..<5) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(heatColor(count: level * 2))
                    .frame(width: 10, height: 10)
            }
            Text("More")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Data

    private var heatMapData: HeatMapData {
        let calendar = Calendar.current
        var weeks: [Date] = []
        let today = Date()

        for i in stride(from: -(weeksToShow - 1), through: 0, by: 1) {
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: i, to: today) {
                weeks.append(viewModel.weekStartDate(for: weekDate))
            }
        }

        return HeatMapData(weeks: weeks)
    }

    private func completionCount(habit: Habit, weekStart: Date) -> Int {
        let calendar = Calendar.current
        guard let record = habit.weekRecords.first(where: {
            calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
        }) else {
            return 0
        }
        return record.completedDays.filter { $0 == .completed }.count
    }

    private func heatColor(count: Int) -> Color {
        switch count {
        case 0: return .gray.opacity(0.15)
        case 1: return theme.completedColor.opacity(0.25)
        case 2: return theme.completedColor.opacity(0.4)
        case 3: return theme.completedColor.opacity(0.55)
        case 4: return theme.completedColor.opacity(0.7)
        case 5: return theme.completedColor.opacity(0.85)
        default: return theme.completedColor
        }
    }

    private func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }
}

private struct HeatMapData {
    let weeks: [Date]
}
