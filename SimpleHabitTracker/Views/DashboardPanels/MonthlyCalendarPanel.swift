import SwiftUI

struct MonthlyCalendarPanel: View {
    let viewModel: HabitViewModel
    let habits: [Habit]
    let isPremium: Bool
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue
    @State private var selectedHabitIndex: Int = 0

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private var selectedHabit: Habit? {
        guard !habits.isEmpty, selectedHabitIndex < habits.count else { return nil }
        return habits[selectedHabitIndex]
    }

    /// Free: current + last month. Premium: 24 months back.
    private var monthsBack: Int {
        isPremium ? 24 : 1
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 8)

            // Habit picker
            Menu {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    Button {
                        selectedHabitIndex = index
                    } label: {
                        if index == selectedHabitIndex {
                            Label(habit.name, systemImage: "checkmark")
                        } else {
                            Text(habit.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedHabit?.name ?? "Select Habit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .animation(nil, value: selectedHabitIndex)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Calendar
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 32) {
                    ForEach((-monthsBack)...0, id: \.self) { offset in
                        SingleMonthView(
                            monthOffset: offset,
                            viewModel: viewModel,
                            habit: selectedHabit,
                            theme: theme
                        )
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 32)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.trailing)
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Single Month

private struct SingleMonthView: View {
    let monthOffset: Int
    let viewModel: HabitViewModel
    let habit: Habit?
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
                        Color.clear.frame(height: 24)
                    } else {
                        dayCell(info)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ info: DayInfo) -> some View {
        VStack(spacing: 2) {
            Text("\(info.day)")
                .font(.system(size: 9, weight: info.isToday ? .bold : .regular))
                .foregroundStyle(info.isFuture ? .quaternary : (info.isToday ? .primary : .secondary))

            Circle()
                .fill(dotColor(for: info))
                .frame(width: 8, height: 8)
                .opacity(info.isFuture ? 0 : 1)
        }
        .frame(height: 24)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !info.isFuture, let date = info.date, let habit else { return }
            let weekOff = weekOffset(for: date)
            let record = viewModel.weekRecord(for: habit, weekOffset: weekOff)
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: date)
            let dayIndex = (dayOfWeek - calendar.firstWeekday + 7) % 7
            guard dayIndex >= 0, dayIndex < record.completedDays.count else { return }
            viewModel.toggleDay(weekRecord: record, dayIndex: dayIndex)
        }
    }

    private func dotColor(for info: DayInfo) -> Color {
        switch info.state {
        case .completed: return theme.completedColor
        case .failed: return theme.failedColor
        case .notCompleted: return .gray.opacity(0.5)
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
            let state: HabitState = isFuture ? .notCompleted : habitState(for: date)

            days.append(DayInfo(day: day, isPlaceholder: false, isFuture: isFuture, isToday: isToday, state: state, date: date))
        }

        while days.count < 42 {
            days.append(.placeholder)
        }

        return (title, days)
    }

    private func habitState(for date: Date) -> HabitState {
        guard let habit else { return .notCompleted }
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayIndex = (dayOfWeek - calendar.firstWeekday + 7) % 7
        let weekStart = viewModel.weekStartDate(for: date)

        guard let record = habit.weekRecords.first(where: {
            calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
        }), dayIndex >= 0, dayIndex < record.completedDays.count else {
            return .notCompleted
        }

        return record.completedDays[dayIndex]
    }
}

private struct DayInfo {
    let day: Int
    let isPlaceholder: Bool
    let isFuture: Bool
    let isToday: Bool
    let state: HabitState
    let date: Date?

    static let placeholder = DayInfo(day: 0, isPlaceholder: true, isFuture: false, isToday: false, state: .notCompleted, date: nil)
}
