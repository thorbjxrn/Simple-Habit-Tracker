import SwiftUI

struct HabitTrackerView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabitAlert = false
    @State private var newHabitName = ""
    @State private var showingDeleteConfirmation = false
    @State private var deleteIndexSet: IndexSet?
    @State private var showingRenameAlert = false
    @State private var renameHabitID: UUID?
    @State private var newHabitNameForRename = ""

    @State private var weekNumber = -1
    @State private var weekday = -1
    
    private func debugLocale() {
        let locale = Calendar.current.locale ?? Locale.current
        print("Locale Identifier: \(locale.identifier)")
        print("First Weekday: \(Calendar.current.firstWeekday)") // 1 = Sunday, 2 = Monday, etc.
        print("Region: \(locale.region?.identifier ?? "Unknown")")
        print("Language: \(locale.language.languageCode?.identifier ?? "Unknown")")
    }
    
    private var currentDayIndex: Int {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let firstWeekday = calendar.firstWeekday
        // Get the current weekday (1 for Sunday, 2 for Monday, etc.)
//        weekday = calendar.component(.weekday, from: Date())
        // Calculate the index based on the locale's first weekday
        return (weekday - firstWeekday + 7) % 7
    }
    
    private func calculateCalendar() {
        let calendar = Calendar.current
        let currentDate = Date()
        weekNumber = calendar.component(.weekOfYear, from: currentDate)
        weekday = calendar.component(.weekday, from: Date())
        debugLocale()
    }

    var body: some View {
        NavigationView {
            VStack() {
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
                                VStack(alignment: .center, spacing:0) {
                                    HStack(alignment: .center) {
                                        ForEach(0..<7) { index in
                                            VStack(alignment: .center, spacing: 4.5) {
                                                Circle()
                                                    .fill(color(for: habit.completedDays[index]))
                                                    .frame(width: 33, height: 33)
                                                    .onTapGesture {
                                                        handleTap(index: index, for: &habit.completedDays)
                                                    }
                                                Circle()
                                                    .fill(todaysColor(day: index))
                                                    .frame(width: 3, height: 3, alignment: .center)
                                                    .shadow(color: .yellow, radius: 0.5, y: 0.25)
                                            }
                                        }
                                    }
                                    .overlay(
                                        LineConnectingConsecutiveDays(days: habit.completedDays, geometry: geometry)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 25)
                    }
                    .onDelete { indexSet in
                        deleteIndexSet = indexSet
                        showingDeleteConfirmation = true
                    }
                }
//                .navigationTitle("Week \(weekNumber), day \(weekday)")
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
        .onAppear(perform: calculateCalendar)
    }

    private func color(for state: Habit.HabitState) -> Color {
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
    private func todaysColor(day: Int) -> Color {
        if day == currentDayIndex {
            Color(.yellow).opacity(1)
        } else {
            Color(.yellow).opacity(0)
        }
    }

    private func handleTap(index: Int, for days: inout [Habit.HabitState]) {
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
                    y: geometry.size.height / 2 + 4.78)
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
        .stroke(Color.green, lineWidth: 9.2) // Adjust the line color and width
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
