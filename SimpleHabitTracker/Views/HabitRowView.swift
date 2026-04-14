import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let weekRecord: WeekRecord
    let currentDayIndex: Int?
    let onToggle: (Int) -> Void
    let onRename: (UUID, String) -> Void
    let onSetWeeklyGoal: ((Habit) -> Void)?
    let isPremium: Bool
    @AppStorage("todayIndicatorStyle") private var useDotIndicator = false
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private var weeklyCompletionCount: Int {
        weekRecord.completedDays.filter { $0 == .completed }.count
    }

    private var isWeeklyGoalMet: Bool? {
        guard let target = habit.targetDaysPerWeek else { return nil }
        return weeklyCompletionCount >= target
    }

    init(
        habit: Habit,
        weekRecord: WeekRecord,
        currentDayIndex: Int?,
        onToggle: @escaping (Int) -> Void,
        onRename: @escaping (UUID, String) -> Void,
        onSetWeeklyGoal: ((Habit) -> Void)? = nil,
        isPremium: Bool = false
    ) {
        self.habit = habit
        self.weekRecord = weekRecord
        self.currentDayIndex = currentDayIndex
        self.onToggle = onToggle
        self.onRename = onRename
        self.onSetWeeklyGoal = onSetWeeklyGoal
        self.isPremium = isPremium
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(habit.name)
                    .font(.headline)
                    .contextMenu {
                        Button(action: {
                            onRename(habit.id, habit.name)
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }

                        if isPremium {
                            Button(action: {
                                onSetWeeklyGoal?(habit)
                            }) {
                                Label("Set Weekly Goal", systemImage: "target")
                            }
                        }
                    }

                if let target = habit.targetDaysPerWeek {
                    Spacer()
                    weeklyGoalBadge(count: weeklyCompletionCount, target: target)
                }
            }

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let state = weekRecord.completedDays[index]
                    let isToday = currentDayIndex == index

                    VStack(spacing: 4) {
                        Circle()
                            .fill(color(for: state))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if isToday && !useDotIndicator {
                                    Circle()
                                        .strokeBorder(Color.yellow, lineWidth: 2.5)
                                }
                            }
                            .onTapGesture {
                                triggerHaptic(for: state)
                                onToggle(index)
                            }

                        if useDotIndicator {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 4, height: 4)
                                .opacity(isToday ? 1 : 0)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Weekly Goal Badge

    @ViewBuilder
    private func weeklyGoalBadge(count: Int, target: Int) -> some View {
        let met = count >= target
        HStack(spacing: 2) {
            if met {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            Text("\(count)/\(target)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(met ? theme.completedColor : .secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(met ? theme.completedColor.opacity(0.15) : Color.secondary.opacity(0.1))
        )
    }

    // MARK: - Haptics

    private func triggerHaptic(for currentState: HabitState) {
        switch currentState {
        case .notCompleted:
            // Next state will be .completed
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .completed:
            // Next state will be .failed
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .failed:
            // Next state will be .notCompleted (reset) — no haptic
            break
        }
    }

    // MARK: - Helpers

    private func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted: return theme.notCompletedColor
        case .completed: return theme.completedColor
        case .failed: return theme.failedColor
        }
    }
}
