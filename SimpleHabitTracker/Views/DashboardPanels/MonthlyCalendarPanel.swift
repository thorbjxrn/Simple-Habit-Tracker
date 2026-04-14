import SwiftUI

struct MonthlyCalendarPanel: View {
    let viewModel: HabitViewModel
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    /// How many months back to allow scrolling
    private let monthsBack = 24

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach((-monthsBack)...0, id: \.self) { offset in
                    SingleMonthView(
                        monthOffset: offset,
                        viewModel: viewModel,
                        theme: theme
                    )
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .defaultScrollAnchor(.trailing)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Single Month

private struct SingleMonthView: View {
    let monthOffset: Int
    let viewModel: HabitViewModel
    let theme: AppTheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var weekdaySymbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    var body: some View {
        let data = monthData
        VStack(spacing: 4) {
            Text(data.title)
                .font(.caption)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(data.days.enumerated()), id: \.offset) { _, info in
                    if info.isPlaceholder {
                        Color.clear.frame(height: 18)
                    } else {
                        dayCell(info)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ info: DayInfo) -> some View {
        VStack(spacing: 1) {
            Text("\(info.day)")
                .font(.system(size: 8, weight: info.isToday ? .bold : .regular))
                .foregroundStyle(info.isFuture ? .quaternary : (info.isToday ? .primary : .secondary))

            Circle()
                .fill(info.color)
                .frame(width: 6, height: 6)
                .opacity(info.isFuture ? 0 : 1)
        }
        .frame(height: 18)
    }

    // MARK: - Data

    private var monthData: (title: String, days: [DayInfo]) {
        let calendar = Calendar.current
        let today = Date()

        guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: today) else {
            return ("", [])
        }

        let year = calendar.component(.year, from: targetMonth)
        let month = calendar.component(.month, from: targetMonth)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return ("", [])
        }

        let title = formatter.string(from: firstOfMonth)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingOffset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let habits = viewModel.fetchHabits()

        var days: [DayInfo] = []

        for _ in 0..<leadingOffset {
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
