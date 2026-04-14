import Foundation
import SwiftData

struct MigrationManager {

    private struct LegacyHabit: Codable {
        let id: UUID
        var name: String
        var completedDays: [LegacyHabitState]

        enum LegacyHabitState: String, Codable {
            case notCompleted
            case completed
            case failed
        }
    }

    static func migrateIfNeeded(context: ModelContext) {
        let habitsKey = "habits"
        let dateKey = "date"

        guard let data = UserDefaults.standard.data(forKey: habitsKey) else {
            return
        }

        guard let legacyHabits = try? JSONDecoder().decode([LegacyHabit].self, from: data) else {
            return
        }

        let calendar = Calendar.current
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let weekStartDate = calendar.date(from: weekComponents) ?? Date()

        for (index, legacyHabit) in legacyHabits.enumerated() {
            let habit = Habit(
                id: legacyHabit.id,
                name: legacyHabit.name,
                sortOrder: index
            )
            context.insert(habit)

            let weekRecord = WeekRecord(weekStartDate: weekStartDate)
            weekRecord.completedDays = legacyHabit.completedDays.map { legacyState in
                switch legacyState {
                case .notCompleted: return .notCompleted
                case .completed: return .completed
                case .failed: return .failed
                }
            }
            weekRecord.habit = habit
            context.insert(weekRecord)
        }

        try? context.save()

        UserDefaults.standard.removeObject(forKey: habitsKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
    }
}
