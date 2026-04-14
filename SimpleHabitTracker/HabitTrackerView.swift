import SwiftUI
import SwiftData

struct HabitTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(AdManager.self) private var adManager: AdManager?
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
    @State private var hasCheckedInterstitialOnAppear = false
    @State private var showingWeeklyGoalSheet = false
    @State private var weeklyGoalHabit: Habit?
    @State private var selectedWeeklyGoal: Int = 0
    @State private var isLandscape: Bool = false

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
                    isPremium: purchaseManager.isPremium
                )
            } else {
                habitListView
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(modelContext: modelContext)
            }

            // Show interstitial on app open (only once per appear)
            if !hasCheckedInterstitialOnAppear {
                hasCheckedInterstitialOnAppear = true
                if let adManager, adManager.shouldShowInterstitial {
                    adManager.showInterstitialIfReady()
                }
                adManager?.requestTrackingPermissionIfNeeded()
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

                List {
                    Section {
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
                            },
                            onSetWeeklyGoal: { habit in
                                presentWeeklyGoalSheet(for: habit)
                            },
                            isPremium: purchaseManager.isPremium
                        )
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first, index < habits.count {
                            habitToDelete = habits[index]
                            showingDeleteConfirmation = true
                        }
                    }
                    } header: {
                        DayOfWeekHeaderView()
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
                // MARK: - Banner Ad
                if !purchaseManager.isPremium {
                    BannerAdView()
                        .frame(height: 50)
                }
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
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
        .sheet(isPresented: $showingWeeklyGoalSheet) {
            weeklyGoalSheet
        }
        .onChange(of: displayedWeekOffset) { oldValue, newValue in
            // Show interstitial when navigating to past weeks
            if newValue < oldValue, newValue < 0 {
                adManager?.showInterstitialIfReady()
            }
        }
    }

    // MARK: - Orientation

    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            isLandscape = true
        } else if orientation.isPortrait {
            isLandscape = false
        }
        // .unknown / .faceUp / .faceDown: keep current value
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
