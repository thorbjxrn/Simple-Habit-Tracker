import SwiftUI

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }

    init() {
        loadHabits()
        checkWeekNr()
    }

    // UserDefaults key
    private let habitsKey = "habits"
    private let lastSeenKey = "date"

    // MARK: - Data Persistence Methods
    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }

    func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }

    func saveDate() {
        if let encoded = try? JSONEncoder().encode(Date()) {
            UserDefaults.standard.set(encoded, forKey: lastSeenKey)
        }
    }

    func checkWeekNr() {
        guard let data = UserDefaults.standard.data(forKey: lastSeenKey),
           let lastSeenDate = try? JSONDecoder().decode(Date.self, from: data) else {
            return
        }

        if Calendar.current.component(.weekOfYear, from: lastSeenDate) != Calendar.current.component(.weekOfYear, from: Date()) {
            print("new week!")
            for i in habits.indices {
                for j in habits[i].completedDays.indices {
                    habits[i].completedDays[j] = .notCompleted
                }
            }
        }

    }

    func addHabit(name: String) {
        let newHabit = Habit(
            id: UUID(),
            name: name,
            completedDays: Array(repeating: .notCompleted, count: 7)
        )
        habits.append(newHabit)
    }

    func removeHabit(at indexSet: IndexSet) {
//        guard let index = indexSet.first else { return }
        habits.remove(atOffsets: indexSet)
    }

    func renameHabit(id: UUID, newName: String) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].name = newName
        }
    }
}
