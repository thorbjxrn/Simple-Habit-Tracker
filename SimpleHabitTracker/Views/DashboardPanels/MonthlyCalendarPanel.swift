import SwiftUI
import SwiftData

struct MonthlyCalendarPanel: View {
    let viewModel: HabitViewModel
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private let monthsBack = 24

    var body: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 32) {
                    ForEach((-monthsBack)...0, id: \.self) { offset in
                        SingleMonthView(
                            monthOffset: offset,
                            viewModel: viewModel,
                            habits: habits,
                            theme: theme
                        )
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 32)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.trailing)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

// MARK: - Single Month

private struct SingleMonthView: View {
    let monthOffset: Int
    let viewModel: HabitViewModel
    let habits: [Habit]
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
                        Color.clear.frame(height: 30)
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
                .font(.system(size: 9, weight: info.isToday ? .bold : .regular))
                .foregroundStyle(info.isFuture ? .quaternary : (info.isToday ? .primary : .secondary))

            if !info.isFuture && !info.habitStates.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(info.habitStates.prefix(5).enumerated()), id: \.offset) { _, state in
                        Circle()
                            .fill(colorForState(state))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !info.isFuture, let date = info.date else { return }
            toggleAllHabits(for: date)
        }
    }

    private func colorForState(_ state: HabitState) -> Color {
        switch state {
        case .completed: return theme.completedColor
        case .failed: return theme.failedColor
        case .notCompleted: return theme.notCompletedColor
        }
    }

    private func toggleAllHabits(for date: Date) {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayIndex = (dayOfWeek - calendar.firstWeekday + 7) % 7

        for habit in habits {
            if habit.createdDate > date { continue }
            let weekRecord = viewModel.weekRecord(for: habit, weekOffset: weekOffset(for: date))
            guard dayIndex >= 0 && dayIndex < weekRecord.completedDays.count else { continue }
            viewModel.toggleDay(weekRecord: weekRecord, dayIndex: dayIndex)
        }
    }

    private func weekOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let currentWeekStart = viewModel.weekStartDate(for: Date())
        let targetWeekStart = viewModel.weekStartDate(for: date)
        let components = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: targetWeekStart)
        return components.weekOfYear ?? 0
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

        var days: [DayInfo] = []

        for _ in 0..<leadingOffset {
            days.append(.placeholder)
        }

        for day in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                continue
            }

            let isFuture = date > today
            let isToday = calendar.isDateInToday(date)

            if isFuture {
                days.append(DayInfo(day: day, isPlaceholder: false, isFuture: true, isToday: false, habitStates: [], date: date))
            } else {
                let states = habitStates(for: date)
                days.append(DayInfo(day: day, isPlaceholder: false, isFuture: false, isToday: isToday, habitStates: states, date: date))
            }
        }

        // Pad to 42 cells (6 rows of 7) so all months have equal height
        while days.count < 42 {
            days.append(.placeholder)
        }

        return (title, days)
    }

    private func habitStates(for date: Date) -> [HabitState] {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayIndex = (dayOfWeek - calendar.firstWeekday + 7) % 7
        let weekStart = viewModel.weekStartDate(for: date)

        var states: [HabitState] = []
        for habit in habits {
            if habit.createdDate > date { continue }
            if let record = habit.weekRecords.first(where: {
                calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
            }), dayIndex >= 0, dayIndex < record.completedDays.count {
                states.append(record.completedDays[dayIndex])
            } else {
                // No record for this week — show as not completed
                states.append(.notCompleted)
            }
        }
        return states
    }
}

private struct DayInfo {
    let day: Int
    let isPlaceholder: Bool
    let isFuture: Bool
    let isToday: Bool
    let habitStates: [HabitState]
    let date: Date?

    static let placeholder = DayInfo(day: 0, isPlaceholder: true, isFuture: false, isToday: false, habitStates: [], date: nil)
}
