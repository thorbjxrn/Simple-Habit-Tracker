import SwiftUI

// Habit model with completion and failure states
struct Habit: Identifiable, Codable {
    let id: UUID
    let name: String
    var completedDays: [HabitState]

    enum HabitState: String, Codable {
        case notCompleted
        case completed
        case failed
    }
}

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }

    init() {
        loadHabits()
    }

    // MARK: - UserDefaults Keys
    private let habitsKey = "habits"

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

    func addHabit(name: String) {
        let newHabit = Habit(id: UUID(), name: name, completedDays: Array(repeating: .notCompleted, count: 7))
        habits.append(newHabit)
    }

    func removeHabit(at indexSet: IndexSet) {
        habits.remove(atOffsets: indexSet)
    }
}

struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabitAlert = false
    @State private var newHabitName = ""

    // Initialize lastTapTime
    @State private var lastTapTime: Date?

    // Get the current day of the week (0 = Sunday, 1 = Monday, etc.)
    private var currentDayIndex: Int {
        Calendar.current.component(.weekday, from: Date()) - 1
    }

    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.habits) { $habit in
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.headline)

                        GeometryReader { geometry in
                            VStack {
                                HStack {
                                    ForEach(0..<7) { index in
                                        Circle()
                                            .fill(color(for: habit.completedDays[index]))
                                            .shadow(color: borderColor(isToday: index), radius: 8, x: 0.0, y: 0.0)
                                            .frame(width: 30, height: 30)
                                            .onTapGesture {
                                                handleTap(index: index, for: &habit.completedDays)
                                            }
                                    }
                                }
                                .overlay(
                                    LineConnectingConsecutiveDays(days: habit.completedDays, geometry: geometry)
                                )
                            }
                        }
                        .frame(height: 50) // Adjust the height as needed
                    }
                    .padding(.vertical)
                }
                .onDelete(perform: viewModel.removeHabit)
            }
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddHabitAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add New Habit", isPresented: $showingAddHabitAlert) {
                TextField("Habit Name", text: $newHabitName)
                Button("Add", action: addNewHabit)
                Button("Cancel", role: .cancel, action: {})
            }
        }
    }

    // Helper functions

    func color(for state: Habit.HabitState) -> Color {
        switch state {
        case .notCompleted:
            return Color.gray
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    func borderColor(isToday: Int) -> Color {
        if isToday == currentDayIndex {
            return Color.accentColor.opacity(0.45)
        } else {
            return Color.accentColor.opacity(0.1)
        }
    }

    func handleTap(index: Int, for days: inout [Habit.HabitState]) {
        let now = Date()

        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < 0.3 {
            markAsFailed(index: index, in: &days)
        } else {
            markAsCompleted(index: index, in: &days)
        }

        lastTapTime = now
    }

    func addNewHabit() {
        guard !newHabitName.isEmpty else { return }
        viewModel.addHabit(name: newHabitName)
        newHabitName = ""
    }

    func markAsCompleted(index: Int, in days: inout [Habit.HabitState]) {
        if days[index] != .completed {
            days[index] = .completed
        } else {
            days[index] = .notCompleted
        }
    }

    func markAsFailed(index: Int, in days: inout [Habit.HabitState]) {
        days[index] = .failed
    }
}

struct LineConnectingConsecutiveDays: View {
    let days: [Habit.HabitState]
    let geometry: GeometryProxy

    private var dayPositions: [CGPoint] {
        let diameter: CGFloat = 30
        let spacing: CGFloat = 10 // Adjust spacing between days if needed
        let circleWidth = diameter + spacing

        return (0..<7).map { index in
            CGPoint(x: CGFloat(index) * circleWidth + diameter / 2,
                    y: geometry.size.height / 3 - 1.5)
        }
    }

    var body: some View {
        Path { path in
            let positions = dayPositions

            for i in 0..<positions.count - 1 {
                if days[i] == .completed && days[i + 1] == .completed {
                    path.move(to: positions[i])
                    path.addLine(to: positions[i + 1])
                }
            }
        }
        .stroke(Color.green, lineWidth: 4) // Adjust the line color and width
    }
}

// Preview
struct HabitTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        HabitTrackerView()
    }
}

#Preview {
    HabitTrackerView()
}
