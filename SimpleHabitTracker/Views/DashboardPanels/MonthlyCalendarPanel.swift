import SwiftUI

struct MonthlyCalendarPanel: View {
    let viewModel: HabitViewModel
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var weekdaySymbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    var body: some View {
        let data = calendarData
        VStack(spacing: 8) {
            Text(data.title)
                .font(.title3)
                .fontWeight(.bold)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(data.days.enumerated()), id: \.offset) { _, dayInfo in
                    if dayInfo.isPlaceholder {
                        Color.clear.frame(height: 28)
                    } else {
                        dayCell(dayInfo)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(_ info: DayInfo) -> some View {
        let isToday = info.isToday
        VStack(spacing: 2) {
            Text("\(info.day)")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundStyle(info.isFuture ? .tertiary : (isToday ? .primary : .secondary))

            Circle()
                .fill(info.color)
                .frame(width: 8, height: 8)
                .opacity(info.isFuture ? 0 : 1)
        }
        .frame(height: 28)
    }

    // MARK: - Calendar Data

    private var calendarData: (title: String, days: [DayInfo]) {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return ("", [])
        }

        let title = formatter.string(from: firstOfMonth)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let habits = viewModel.fetchHabits()

        var days: [DayInfo] = []

        for _ in 0..<offset {
            days.append(DayInfo(day: 0, color: .clear, isPlaceholder: true, isFuture: false, isToday: false))
        }

        for day in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                continue
            }

            let isFuture = date > today
            let isToday = calendar.isDateInToday(date)

            if isFuture {
                days.append(DayInfo(day: day, color: .clear, isPlaceholder: false, isFuture: true, isToday: false))
            } else {
                let color = aggregateColor(for: date, habits: habits)
                days.append(DayInfo(day: day, color: color, isPlaceholder: false, isFuture: false, isToday: isToday))
            }
        }

        return (title, days)
    }

    // MARK: - Aggregate Color

    private func aggregateColor(for date: Date, habits: [Habit]) -> Color {
        let calendar = Calendar.current
        guard !habits.isEmpty else { return theme.notCompletedColor }

        var completedCount = 0
        var failedCount = 0
        var totalTracked = 0

        for habit in habits {
            if habit.createdDate > date { continue }

            let weekStart = viewModel.weekStartDate(for: date)
            guard let record = habit.weekRecords.first(where: {
                calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
            }) else { continue }

            let dayOfWeek = calendar.component(.weekday, from: date)
            let dayIndex = (dayOfWeek - calendar.firstWeekday + 7) % 7
            guard dayIndex >= 0 && dayIndex < record.completedDays.count else { continue }

            totalTracked += 1
            switch record.completedDays[dayIndex] {
            case .completed: completedCount += 1
            case .failed: failedCount += 1
            case .notCompleted: break
            }
        }

        if totalTracked == 0 { return theme.notCompletedColor }
        if completedCount > failedCount { return theme.completedColor }
        if failedCount > completedCount { return theme.failedColor }
        if completedCount > 0 { return theme.completedColor }
        return theme.notCompletedColor
    }
}

private struct DayInfo {
    let day: Int
    let color: Color
    let isPlaceholder: Bool
    let isFuture: Bool
    let isToday: Bool
}
