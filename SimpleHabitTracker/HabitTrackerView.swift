import SwiftUI

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
        let newHabit = Habit(
            id: UUID(),
            name: name,
            completedDays: Array(repeating: .notCompleted, count: 7)
        )
        habits.append(newHabit)
    }

    func removeHabit(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        habits.remove(atOffsets: indexSet)
    }

    func renameHabit(id: UUID, newName: String) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].name = newName
        }
    }
}

struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabitAlert = false
    @State private var newHabitName = ""
    @State private var showingDeleteConfirmation = false
    @State private var deleteIndexSet: IndexSet?
    @State private var showingRenameAlert = false
    @State private var renameHabitID: UUID?
    @State private var newHabitNameForRename = ""

    @State private var undoButtonVisible = false

    // Get the current day of the week (0 = Sunday, 1 = Monday, etc.)
    private var currentDayIndex: Int {
        Calendar.current.component(.weekday, from: Date()) - 1
    }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach($viewModel.habits) { $habit in
                        VStack(alignment: .leading) {
                            Text(habit.name)
                                .lineLimit(0)
                                .font(.headline)
                                .contextMenu {
                                    Button(action: {
                                        renameHabit(id: habit.id, currentName: habit.name)
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                }
                            GeometryReader { geometry in
                                VStack(alignment: .center) {
                                    HStack(alignment: .center) {
                                        ForEach(0..<7) { index in
                                            Circle()
                                                .fill(color(for: habit.completedDays[index]))
                                                .shadow(color: borderColor(for: habit.completedDays[index], isToday: index), radius: 3, x: 0.0, y: 0.0)
                                                .frame(width: 33, height: 33)
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
                        }
                        .padding(.vertical)
                    }
                    .onDelete { indexSet in
                        deleteIndexSet = indexSet
                        showingDeleteConfirmation = true
                    }
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
                .confirmationDialog(
                    "Are you sure you want to delete this habit?",
                    isPresented: $showingDeleteConfirmation,
                    actions: {
                        Button("Delete", role: .destructive) {
                            if let indexSet = deleteIndexSet {
                                viewModel.removeHabit(at: indexSet)
                                undoButtonVisible = true
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                )
            }
        }
        .alert("Rename Habit", isPresented: $showingRenameAlert) {
            TextField("New Habit Name", text: $newHabitNameForRename)
            Button("Rename") {
                if let id = renameHabitID {
                    viewModel.renameHabit(id: id, newName: newHabitNameForRename)
                }
                newHabitNameForRename = ""
            }
            Button("Cancel", role: .cancel, action: {})
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

    // perhaps I could make a circle class that can be adjusted by parameters instead of doing it all in functional programming
    func borderColor(for state: Habit.HabitState, isToday: Int) -> Color {
        if isToday == currentDayIndex {
            return color(for: state).opacity(0.425)
        } else {
            return color(for: state).opacity(0.15)
        }
    }

    func handleTap(index: Int, for days: inout [Habit.HabitState]) {
        if days[index] == .completed {
            days[index] = .failed
        } else if days[index] == .failed {
            days[index] = .notCompleted
        } else {
            days[index] = .completed
        }
    }

    func addNewHabit() {
        guard !newHabitName.isEmpty else { return }
        viewModel.addHabit(name: newHabitName)
        newHabitName = ""
    }

    func renameHabit(id: UUID, currentName: String) {
        newHabitNameForRename = currentName
        renameHabitID = id
        showingRenameAlert = true
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
                    y: geometry.size.height / 2 + 4.5)
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
        .stroke(Color.green, lineWidth: 11) // Adjust the line color and width
        .shadow(color: Color.green.opacity(0.15), radius: 3)
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
