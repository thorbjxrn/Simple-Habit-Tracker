import Foundation
import SwiftData

@Observable
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

        if let existing = habit.weekRecords.first(where: {
            Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
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

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
