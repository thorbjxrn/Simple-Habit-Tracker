import Foundation
import SwiftData

@Model
final class WeekRecord {
    var id: UUID
    var weekStartDate: Date
    var completedDaysRaw: [String]
    var habit: Habit?

    var completedDays: [HabitState] {
        get {
            completedDaysRaw.compactMap { HabitState(rawValue: $0) }
        }
        set {
            completedDaysRaw = newValue.map { $0.rawValue }
        }
    }

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        habit: Habit? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.completedDaysRaw = Array(repeating: HabitState.notCompleted.rawValue, count: 7)
        self.habit = habit
    }
}
