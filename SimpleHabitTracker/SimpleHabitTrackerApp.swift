import SwiftUI
import SwiftData

@main
struct SimpleHabitTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            HabitTrackerView()
        }
        .modelContainer(for: Habit.self)
    }
}
