import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var completedDays: [HabitState]

    enum HabitState: String, Codable {
        case notCompleted
        case completed
        case failed
    }
}
