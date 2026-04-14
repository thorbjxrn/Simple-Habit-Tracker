import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var viewModel: HabitViewModel?
    @State private var showingAddHabitAlert = false
    @State private var newHabitName = ""
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    @State private var showingRenameAlert = false
    @State private var renameHabitID: UUID?
    @State private var newHabitNameForRename = ""
    @State private var hasMigrated = false

    private var currentDayIndex: Int {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let firstWeekday = calendar.firstWeekday
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday - firstWeekday + 7) % 7
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(habits) { habit in
                        let weekRecord = resolvedWeekRecord(for: habit)
                        VStack(alignment: .leading) {
                            Text(habit.name)
                                .lineLimit(nil)
                                .font(.headline)
                                .contextMenu {
                                    Button(action: {
                                        renameHabit(id: habit.id, currentName: habit.name)
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                }
                            GeometryReader { geometry in
                                VStack(alignment: .center, spacing: 0) {
                                    HStack(alignment: .center) {
                                        ForEach(0..<7) { index in
                                            VStack(alignment: .center, spacing: 4.5) {
                                                Circle()
                                                    .fill(color(for: weekRecord.completedDays[index]))
                                                    .frame(width: 33, height: 33)
                                                    .onTapGesture {
                                                        viewModel?.toggleDay(weekRecord: weekRecord, dayIndex: index)
                                                    }
                                                Circle()
                                                    .fill(todaysColor(day: index))
                                                    .frame(width: 3, height: 3, alignment: .center)
                                                    .shadow(color: .yellow, radius: 0.5, y: 0.25)
                                            }
                                        }
                                    }
                                    .overlay(
                                        LineConnectingConsecutiveDays(days: weekRecord.completedDays, geometry: geometry)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 25)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first, index < habits.count {
                            habitToDelete = habits[index]
                            showingDeleteConfirmation = true
                        }
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
                            if let habit = habitToDelete {
                                viewModel?.removeHabit(habit)
                            }
                            habitToDelete = nil
                        }
                        Button("Cancel", role: .cancel) {
                            habitToDelete = nil
                        }
                    }
                )
            }
        }
        .alert("Rename Habit", isPresented: $showingRenameAlert) {
            TextField("New Habit Name", text: $newHabitNameForRename)
            Button("Rename") {
                if let id = renameHabitID,
                   let habit = habits.first(where: { $0.id == id }) {
                    viewModel?.renameHabit(habit, newName: newHabitNameForRename)
                }
                newHabitNameForRename = ""
            }
            Button("Cancel", role: .cancel, action: {})
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(modelContext: modelContext)
            }
            if !hasMigrated {
                MigrationManager.migrateIfNeeded(context: modelContext)
                hasMigrated = true
            }
        }
    }

    // MARK: - Helpers

    private func resolvedWeekRecord(for habit: Habit) -> WeekRecord {
        guard let vm = viewModel else {
            // Fallback: should not happen after onAppear
            return WeekRecord(weekStartDate: Date())
        }
        return vm.currentWeekRecord(for: habit)
    }

    func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted:
            return Color.gray
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    func todaysColor(day: Int) -> Color {
        if day == currentDayIndex {
            Color(.yellow).opacity(1)
        } else {
            Color(.yellow).opacity(0)
        }
    }

    func addNewHabit() {
        guard !newHabitName.isEmpty else { return }
        viewModel?.addHabit(name: newHabitName)
        newHabitName = ""
    }

    func renameHabit(id: UUID, currentName: String) {
        newHabitNameForRename = currentName
        renameHabitID = id
        showingRenameAlert = true
    }
}

struct LineConnectingConsecutiveDays: View {
    let days: [HabitState]
    let geometry: GeometryProxy

    private var dayPositions: [CGPoint] {
        let diameter: CGFloat = 30
        let spacing: CGFloat = 10
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
        .stroke(Color.green, lineWidth: 9.2)
        .shadow(color: Color.green.opacity(0.15), radius: 3)
    }
}

#Preview {
    HabitTrackerView()
        .modelContainer(for: Habit.self, inMemory: true)
}
