import SwiftUI
import SwiftData

struct HeatmapPanel: View {
    let viewModel: HabitViewModel
    let isPremium: Bool
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private var weeksToShow: Int {
        isPremium ? 26 : 2
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 3
            let lockedColumns = isPremium ? 0 : 4
            let nameWidth: CGFloat = min(140, geo.size.width * 0.2)
            let availableWidth = geo.size.width - nameWidth - 48 // padding
            let maxColumns = max(1, Int(availableWidth / 48))
            let visibleWeekCount = min(maxColumns, weeksToShow)
            let totalColumns = CGFloat(visibleWeekCount + lockedColumns)
            let availableHeight = geo.size.height - 120
            let cellFromWidth = (availableWidth - spacing * totalColumns) / totalColumns
            let cellFromHeight = (availableHeight - spacing * CGFloat(max(habits.count, 1))) / CGFloat(max(habits.count, 1) + 1)
            let cellSize = max(16, min(44, min(cellFromWidth, cellFromHeight)))

            VStack(spacing: 16) {
                Spacer()

                Text("Heatmap")
                    .font(.title3)
                    .fontWeight(.bold)

                if habits.isEmpty {
                    Text("Add habits to see your heatmap")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: spacing) {
                        // Week header row
                        HStack(spacing: spacing) {
                            Color.clear.frame(width: nameWidth, height: cellSize * 0.5)

                            if !isPremium {
                                ForEach(0..<lockedColumns, id: \.self) { _ in
                                    Color.clear.frame(width: cellSize, height: cellSize * 0.5)
                                }
                            }

                            ForEach(recentWeeks(count: visibleWeekCount), id: \.self) { weekStart in
                                Text(weekLabel(for: weekStart))
                                    .font(.system(size: min(10, cellSize * 0.4)))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: cellSize, height: cellSize * 0.5)
                            }
                        }

                        // One row per habit
                        ForEach(habits) { habit in
                            HStack(spacing: spacing) {
                                Text(habit.name)
                                    .font(.system(size: min(12, cellSize * 0.5)))
                                    .foregroundStyle(.secondary)
                                    .frame(width: nameWidth, alignment: .trailing)

                                if !isPremium {
                                    ForEach(0..<lockedColumns, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: min(10, cellSize * 0.3)))
                                                    .foregroundStyle(.secondary.opacity(0.4))
                                            }
                                    }
                                }

                                ForEach(recentWeeks(count: visibleWeekCount), id: \.self) { weekStart in
                                    let count = completionCount(habit: habit, weekStart: weekStart)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(heatColor(count: count))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                    .padding(.trailing, nameWidth)
                    .frame(maxWidth: .infinity)

                    // Legend
                    HStack(spacing: 6) {
                        Text("Less")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(count: level * 2))
                                .frame(width: 12, height: 12)
                        }
                        Text("More")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }

                    if !isPremium {
                        Text("Upgrade for full history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Data

    private func recentWeeks(count: Int) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var weeks: [Date] = []

        for i in stride(from: -(count - 1), through: 0, by: 1) {
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: i, to: today) {
                weeks.append(viewModel.weekStartDate(for: weekDate))
            }
        }
        return weeks
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
