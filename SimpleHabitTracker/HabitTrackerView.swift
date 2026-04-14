import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(AdManager.self) private var adManager
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var viewModel: HabitViewModel?
    @State private var isLandscape = false
    @State private var addHabitAlertID = UUID()
    @State private var showingAddHabitAlert = false
    @State private var newHabitName = ""
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    @State private var showingRenameAlert = false
    @State private var renameHabitID: UUID?
    @State private var newHabitNameForRename = ""
    @State private var displayedWeekOffset: Int = 0
    @State private var showPaywall: Bool = false
    @State private var hasCheckedInterstitialOnAppear = false
    @State private var showingWeeklyGoalSheet = false
    @State private var weeklyGoalHabit: Habit?
    @State private var selectedWeeklyGoal: Int = 0
    @State private var habitPlaceholder: String = ""

    private static let placeholders = [
        "Drink water",
        "Read 10 pages",
        "Go for a walk",
        "Meditate",
        "No phone in bed",
        "Stretch",
        "Call a friend",
        "Cook at home",
        "Journal",
        "Touch grass",
        "Inbox zero",
        "Floss",
        "Practice guitar",
        "Learn a word",
        "Take the stairs",
        "No snooze",
        "Eat a vegetable",
        "Compliment someone",
        "Ship something",
        "Deep breaths",
    ]

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
        Group {
            if isLandscape, let vm = viewModel {
                DashboardView(
                    viewModel: vm,
                    habits: habits,
                    isPremium: purchaseManager.isPremium
                )
            } else {
                habitListView
            }
        }
        .onAppear {
            if viewModel == nil {
                MigrationManager.migrateIfNeeded(context: modelContext)
                viewModel = HabitViewModel(modelContext: modelContext)
            }

            if !hasCheckedInterstitialOnAppear {
                hasCheckedInterstitialOnAppear = true
                adManager.requestTrackingPermissionIfNeeded()
            }

            updateOrientation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
    }

    // MARK: - Habit List View (Portrait)

    private var habitListView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WeekNavigationView(
                    weekOffset: $displayedWeekOffset,
                    isPremium: purchaseManager.isPremium,
                    canNavigate: { offset in
                        viewModel?.canNavigateToWeek(offset: offset, isPremium: purchaseManager.isPremium) ?? false
                    },
                    showPaywall: $showPaywall
                )

                if habits.isEmpty {
                    ContentUnavailableView {
                        Label("No Habits", systemImage: "checkmark.circle.badge.plus")
                    } description: {
                        Text("Tap + to add your first habit")
                    }
                } else {
                    weekPageView
                }

                // MARK: - Banner Ad
                if adManager.shouldShowBanner {
                    BannerAdView()
                        .frame(height: 50)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel?.canAddHabit(isPremium: purchaseManager.isPremium) == true {
                            habitPlaceholder = Self.placeholders.filter { $0 != habitPlaceholder }.randomElement() ?? "Habit Name"
                            addHabitAlertID = UUID()
                            showingAddHabitAlert = true
                        } else {
                            showPaywall = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add New Habit", isPresented: $showingAddHabitAlert) {
                TextField(habitPlaceholder, text: $newHabitName)
                Button("Add", action: addNewHabit)
                Button("Cancel", role: .cancel, action: {})
            }
            .id(addHabitAlertID)
            .alert("Delete \(habitToDelete?.name ?? "habit")?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        viewModel?.removeHabit(habit)
                    }
                    habitToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
            } message: {
                Text("This will remove the habit and all its history.")
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
        .sheet(isPresented: $showPaywall, onDismiss: {
            // Snap back from the hidden limit page if still there
            if !purchaseManager.isPremium && displayedWeekOffset == minWeekOffset {
                withAnimation { displayedWeekOffset = minWeekOffset + 1 }
            }
        }) {
            PaywallView(purchaseManager: purchaseManager)
        }
        .sheet(isPresented: $showingWeeklyGoalSheet) {
            weeklyGoalSheet
        }
        .onChange(of: displayedWeekOffset) { oldValue, newValue in
            if newValue < oldValue, newValue < 0 {
                if adManager.onHistoryNavigation() {
                    adManager.showInterstitialIfReady()
                }
            }
            // Show paywall when swiping past the free tier limit
            if !purchaseManager.isPremium && newValue == minWeekOffset {
                showPaywall = true
            }
        }
    }

    // MARK: - Week Page View

    private var minWeekOffset: Int {
        purchaseManager.isPremium ? -52 : -2
    }

    private var weekPageView: some View {
        TabView(selection: $displayedWeekOffset) {
            ForEach(minWeekOffset...0, id: \.self) { offset in
                List {
                    Section {
                        ForEach(habits) { habit in
                            let weekRecord = weekRecordForOffset(habit: habit, offset: offset)
                            HabitRowView(
                                habit: habit,
                                weekRecord: weekRecord,
                                currentDayIndex: offset == 0 ? currentDayIndex : nil,
                                onToggle: { dayIndex in
                                    viewModel?.toggleDay(weekRecord: weekRecord, dayIndex: dayIndex)
                                },
                                onRename: { id, currentName in
                                    renameHabit(id: id, currentName: currentName)
                                },
                                onDelete: { habit in
                                    habitToDelete = habit
                                    showingDeleteConfirmation = true
                                },
                                onSetWeeklyGoal: { habit in
                                    presentWeeklyGoalSheet(for: habit)
                                },
                                isPremium: purchaseManager.isPremium
                            )
                        }
                    } header: {
                        DayOfWeekHeaderView()
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func weekRecordForOffset(habit: Habit, offset: Int) -> WeekRecord {
        guard let vm = viewModel else {
            return WeekRecord(weekStartDate: Date())
        }
        // Don't create records for the hidden paywall page
        if !purchaseManager.isPremium && offset == minWeekOffset {
            return WeekRecord(weekStartDate: vm.weekStartDate(for: Date()))
        }
        return vm.weekRecord(for: habit, weekOffset: offset)
    }

    // MARK: - Orientation

    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            isLandscape = true
        case .portrait, .portraitUpsideDown:
            isLandscape = false
        default:
            break
        }
    }

    // MARK: - Helpers

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

    func presentWeeklyGoalSheet(for habit: Habit) {
        weeklyGoalHabit = habit
        selectedWeeklyGoal = habit.targetDaysPerWeek ?? 0
        showingWeeklyGoalSheet = true
    }

    // MARK: - Weekly Goal Sheet

    private var weeklyGoalSheet: some View {
        NavigationStack {
            Form {
                Picker("Days per Week", selection: $selectedWeeklyGoal) {
                    Text("No Goal").tag(0)
                    ForEach(1...7, id: \.self) { count in
                        Text("\(count) \(count == 1 ? "day" : "days")").tag(count)
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Weekly Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingWeeklyGoalSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let habit = weeklyGoalHabit {
                            viewModel?.setWeeklyGoal(for: habit, target: selectedWeeklyGoal == 0 ? nil : selectedWeeklyGoal)
                        }
                        showingWeeklyGoalSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HabitTrackerView()
        .environment(PurchaseManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
