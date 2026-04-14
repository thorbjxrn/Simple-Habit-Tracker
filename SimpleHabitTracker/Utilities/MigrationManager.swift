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

    private static let migrationKey = "didMigrateToSwiftData_v1"
    private static let habitsKey = "habits"
    private static let dateKey = "date"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        guard let data = UserDefaults.standard.data(forKey: habitsKey) else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        guard let legacyHabits = try? JSONDecoder().decode([LegacyHabit].self, from: data) else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        let calendar = Calendar.current
        let referenceDate: Date
        if let savedDateData = UserDefaults.standard.data(forKey: dateKey),
           let lastSeenDate = try? JSONDecoder().decode(Date.self, from: savedDateData) {
            referenceDate = lastSeenDate
        } else {
            referenceDate = Date()
        }
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
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

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
            UserDefaults.standard.removeObject(forKey: habitsKey)
            UserDefaults.standard.removeObject(forKey: dateKey)
        } catch {
            print("Migration failed: \(error)")
        }
    }
}
