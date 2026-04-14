import SwiftUI

struct MonthlyCalendarPanel: View {
    let viewModel: HabitViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Short weekday symbols starting from the calendar's first weekday
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let calendar = Calendar.current
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }()

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

        // Determine the weekday of the first day (adjusted for calendar's first weekday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [DayInfo] = []

        // Add empty cells for days before the 1st
        for _ in 0..<offset {
            days.append(DayInfo(day: 0, color: .clear, isPlaceholder: true))
        }

        let habits = viewModel.fetchHabits()

        for day in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                days.append(DayInfo(day: day, color: .gray.opacity(0.3), isPlaceholder: false))
                continue
            }

            if date > today {
                // Future day
                days.append(DayInfo(day: day, color: .clear, isPlaceholder: false))
                continue
            }

            let color = aggregateColor(for: date, habits: habits)
            days.append(DayInfo(day: day, color: color, isPlaceholder: false))
        }

        return (title, days)
    }

    var body: some View {
        let data = calendarData
        VStack(spacing: 12) {
            Text(data.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(data.days.enumerated()), id: \.offset) { _, dayInfo in
                    if dayInfo.isPlaceholder {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dayInfo.color)
                                .aspectRatio(1, contentMode: .fit)
                            if dayInfo.day > 0 && dayInfo.color != .clear {
                                Text("\(dayInfo.day)")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            } else if dayInfo.day > 0 {
                                Text("\(dayInfo.day)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func aggregateColor(for date: Date, habits: [Habit]) -> Color {
        let calendar = Calendar.current

        guard !habits.isEmpty else { return .gray.opacity(0.3) }

        var completedCount = 0
        var failedCount = 0
        var totalTracked = 0

        for habit in habits {
            // Only count habits that existed on this date
            if habit.createdDate > date { continue }

            let weekStart = viewModel.weekStartDate(for: date)
            guard let record = habit.weekRecords.first(where: {
                calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
            }) else { continue }

            let dayOfWeek = calendar.component(.weekday, from: date)
            let firstWeekday = calendar.firstWeekday
            let dayIndex = (dayOfWeek - firstWeekday + 7) % 7

            guard dayIndex >= 0 && dayIndex < record.completedDays.count else { continue }

            totalTracked += 1
            switch record.completedDays[dayIndex] {
            case .completed:
                completedCount += 1
            case .failed:
                failedCount += 1
            case .notCompleted:
                break
            }
        }

        if totalTracked == 0 { return .gray.opacity(0.3) }

        if completedCount > failedCount && completedCount > 0 {
            return .green
        } else if failedCount > completedCount && failedCount > 0 {
            return .red
        } else if completedCount > 0 && failedCount > 0 {
            // Tie goes to green
            return .green
        }
        return .gray.opacity(0.3)
    }
}

// MARK: - Day Info Model

private struct DayInfo {
    let day: Int
    let color: Color
    let isPlaceholder: Bool
}
