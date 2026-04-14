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
        let startOfWeek = weekStartDate(for: Date())

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
