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
    @State private var displayedWeekOffset: Int = 0
    @State private var showPaywall: Bool = false

    private var isCurrentWeek: Bool {
        displayedWeekOffset == 0
    }

    private var currentDayIndex: Int? {
        guard isCurrentWeek else { return nil }
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let firstWeekday = calendar.firstWeekday
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday - firstWeekday + 7) % 7
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WeekNavigationView(
                    weekOffset: $displayedWeekOffset,
                    isPremium: false,
                    canNavigate: { offset in
                        viewModel?.canNavigateToWeek(offset: offset, isPremium: false) ?? false
                    },
                    showPaywall: $showPaywall
                )

                DayOfWeekHeaderView()
                    .padding(.bottom, 4)

                List {
                    ForEach(habits) { habit in
                        let weekRecord = resolvedWeekRecord(for: habit)
                        HabitRowView(
                            habit: habit,
                            weekRecord: weekRecord,
                            currentDayIndex: currentDayIndex,
                            onToggle: { dayIndex in
                                viewModel?.toggleDay(weekRecord: weekRecord, dayIndex: dayIndex)
                            },
                            onRename: { id, currentName in
                                renameHabit(id: id, currentName: currentName)
                            }
                        )
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
        .alert("Premium Feature", isPresented: $showPaywall) {
            Button("OK", role: .cancel, action: {})
        } message: {
            Text("Viewing weeks beyond last week requires Premium. Upgrade to unlock full history.")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(modelContext: modelContext)
            }
        }
    }

    // MARK: - Helpers

    private func resolvedWeekRecord(for habit: Habit) -> WeekRecord {
        guard let vm = viewModel else {
            // Fallback: should not happen after onAppear
            return WeekRecord(weekStartDate: Date())
        }
        return vm.weekRecord(for: habit, weekOffset: displayedWeekOffset)
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
