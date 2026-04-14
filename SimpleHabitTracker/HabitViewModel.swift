import Foundation
import SwiftData

@Observable
@MainActor
final class HabitViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Habit CRUD

    func addHabit(name: String) {
        let existingHabits = fetchHabits()
        let nextSortOrder = (existingHabits.map(\.sortOrder).max() ?? -1) + 1

        let habit = Habit(name: name, sortOrder: nextSortOrder)
        modelContext.insert(habit)

        let weekRecord = WeekRecord(weekStartDate: weekStartDate(for: Date()))
        weekRecord.habit = habit
        modelContext.insert(weekRecord)

        save()
    }

    func removeHabit(_ habit: Habit) {
        modelContext.delete(habit)
        save()
    }

    func renameHabit(_ habit: Habit, newName: String) {
        habit.name = newName
        save()
    }

    // MARK: - Weekly Goals

    func setWeeklyGoal(for habit: Habit, target: Int?) {
        habit.targetDaysPerWeek = target
        save()
    }

    func weeklyCompletionCount(for habit: Habit, weekRecord: WeekRecord) -> Int {
        weekRecord.completedDays.filter { $0 == .completed }.count
    }

    func isWeeklyGoalMet(for habit: Habit, weekRecord: WeekRecord) -> Bool? {
        guard let target = habit.targetDaysPerWeek else { return nil }
        return weeklyCompletionCount(for: habit, weekRecord: weekRecord) >= target
    }

    // MARK: - Day Toggle

    func toggleDay(weekRecord: WeekRecord, dayIndex: Int) {
        guard dayIndex >= 0 && dayIndex < weekRecord.completedDays.count else { return }

        var days = weekRecord.completedDays
        switch days[dayIndex] {
        case .notCompleted:
            days[dayIndex] = .completed
        case .completed:
            days[dayIndex] = .failed
        case .failed:
            days[dayIndex] = .notCompleted
        }
        weekRecord.completedDays = days
        save()
    }

    // MARK: - Week Record Access

    func currentWeekRecord(for habit: Habit) -> WeekRecord {
        return weekRecord(for: habit, weekOffset: 0)
    }

    func weekRecord(for habit: Habit, weekOffset: Int) -> WeekRecord {
        let targetDate = dateForWeekOffset(weekOffset)
        let startOfWeek = weekStartDate(for: targetDate)
        let calendar = Calendar.current

        // Fetch all WeekRecords and filter in memory
        // (SwiftData predicates on optional relationships are unreliable)
        let allRecords = (try? modelContext.fetch(FetchDescriptor<WeekRecord>())) ?? []
        if let existing = allRecords.first(where: { record in
            record.habit?.id == habit.id &&
            calendar.isDate(record.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
        }) {
            return existing
        }

        let weekRecord = WeekRecord(weekStartDate: startOfWeek)
        weekRecord.habit = habit
        modelContext.insert(weekRecord)
        save()
        return weekRecord
    }

    // MARK: - Week Navigation

    func canNavigateToWeek(offset: Int, isPremium: Bool) -> Bool {
        if isPremium { return true }
        // Free tier: only current week (0) and last week (-1)
        return offset >= -1 && offset <= 0
    }

    func weekDateRange(for offset: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let targetDate = dateForWeekOffset(offset)
        let start = weekStartDate(for: targetDate)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        return (start, end)
    }

    private func dateForWeekOffset(_ offset: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfYear, value: offset, to: Date()) ?? Date()
    }

    // MARK: - Week Utilities

    func weekStartDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    // MARK: - Business Rules

    func canAddHabit(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return fetchHabits().count < 5
    }

    // MARK: - Fetching

    func fetchHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Dashboard Queries

    /// Aggregate completion percentage for all habits in a given week offset.
    func weeklyCompletionPercentage(for weekOffset: Int) -> Double {
        let habits = fetchHabits()
        guard !habits.isEmpty else { return 0 }

        let targetDate = dateForWeekOffset(weekOffset)
        let startOfWeek = weekStartDate(for: targetDate)
        let calendar = Calendar.current

        var totalPossible = 0
        var totalCompleted = 0

        for habit in habits {
            // Only count days from habit creation or week start, whichever is later
            guard let record = habit.weekRecords.first(where: {
                calendar.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
            }) else { continue }

            for state in record.completedDays {
                totalPossible += 1
                if state == .completed {
                    totalCompleted += 1
                }
            }
        }

        guard totalPossible > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalPossible) * 100
    }

    /// Returns data points for the trend chart (most recent weeks first, reversed to chronological).
    func completionData(weekCount: Int) -> [(weekStart: Date, percentage: Double)] {
        var results: [(weekStart: Date, percentage: Double)] = []

        for offset in stride(from: -(weekCount - 1), through: 0, by: 1) {
            let targetDate = dateForWeekOffset(offset)
            let startOfWeek = weekStartDate(for: targetDate)
            let pct = weeklyCompletionPercentage(for: offset)
            results.append((weekStart: startOfWeek, percentage: pct))
        }

        return results
    }

    /// Consecutive weeks (going back from current) with at least one completion across any habit.
    func currentStreak() -> Int {
        let habits = fetchHabits()
        guard !habits.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var offset = 0

        while true {
            let targetDate = dateForWeekOffset(offset)
            let startOfWeek = weekStartDate(for: targetDate)

            var hasCompletion = false
            for habit in habits {
                if let record = habit.weekRecords.first(where: {
                    calendar.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
                }) {
                    if record.completedDays.contains(.completed) {
                        hasCompletion = true
                        break
                    }
                }
            }

            if hasCompletion {
                streak += 1
                offset -= 1
            } else {
                break
            }

            // Safety limit to prevent infinite loops
            if abs(offset) > 520 { break }
        }

        return streak
    }

    /// Highest number of completions across all habits in any single week.
    func bestWeekCompletionCount() -> Int {
        let habits = fetchHabits()
        guard !habits.isEmpty else { return 0 }

        // Collect all unique week start dates
        var weekStarts = Set<Date>()
        let calendar = Calendar.current

        for habit in habits {
            for record in habit.weekRecords {
                // Normalize to start of day for comparison
                let normalized = calendar.startOfDay(for: record.weekStartDate)
                weekStarts.insert(normalized)
            }
        }

        var bestCount = 0

        for weekStart in weekStarts {
            var weekTotal = 0
            for habit in habits {
                if let record = habit.weekRecords.first(where: {
                    calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day)
                }) {
                    weekTotal += record.completedDays.filter { $0 == .completed }.count
                }
            }
            bestCount = max(bestCount, weekTotal)
        }

        return bestCount
    }

    /// Total completed days divided by total possible days across all time.
    func overallCompletionRate() -> Double {
        let habits = fetchHabits()
        guard !habits.isEmpty else { return 0 }

        var totalPossible = 0
        var totalCompleted = 0

        for habit in habits {
            for record in habit.weekRecords {
                for state in record.completedDays {
                    totalPossible += 1
                    if state == .completed {
                        totalCompleted += 1
                    }
                }
            }
        }

        guard totalPossible > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalPossible)
    }

    /// Sum of all completed days across all habits and all time.
    func totalCompletions() -> Int {
        let habits = fetchHabits()
        var total = 0

        for habit in habits {
            for record in habit.weekRecords {
                total += record.completedDays.filter { $0 == .completed }.count
            }
        }

        return total
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
