import SwiftUI
import WidgetKit
import AppIntents
import SwiftData

struct SingleHabitTodayEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitID: UUID?
    let todayState: HabitState
    let dayIndex: Int
    let theme: WidgetTheme
    let weeklyCompletions: Int
    let weeklyTarget: Int?
}

struct SingleHabitTodayProvider: AppIntentTimelineProvider {
    typealias Entry = SingleHabitTodayEntry
    typealias Intent = SingleHabitTodayIntent

    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            habitName: "Habit",
            habitID: nil,
            todayState: .notCompleted,
            dayIndex: 0,
            theme: .current(),
            weeklyCompletions: 3,
            weeklyTarget: 5
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = makeEntry(for: configuration)
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func makeEntry(for configuration: Intent) -> Entry {
        guard let selectedHabit = configuration.habit,
              let container = try? SharedModelContainer.create(forWidget: true) else {
            return Entry(
                date: Date(),
                habitName: "Select a habit",
                habitID: nil,
                todayState: .notCompleted,
                dayIndex: WidgetDateHelpers.todayDayIndex,
                theme: .current(),
                weeklyCompletions: 0,
                weeklyTarget: nil
            )
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(descriptor)) ?? []
        let dayIndex = WidgetDateHelpers.todayDayIndex

        guard let habit = habits.first(where: { $0.id == selectedHabit.id }) else {
            return Entry(
                date: Date(),
                habitName: selectedHabit.name,
                habitID: selectedHabit.id,
                todayState: .notCompleted,
                dayIndex: dayIndex,
                theme: .current(),
                weeklyCompletions: 0,
                weeklyTarget: nil
            )
        }

        let startOfWeek = SharedModelContainer.weekStartDate(for: Date())
        let record = (habit.weekRecords ?? []).first(where: {
            Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
        })
        let todayState = record?.completedDays[dayIndex] ?? .notCompleted
        let weeklyCompletions = record?.completedDays.filter { $0 == .completed }.count ?? 0

        return Entry(
            date: Date(),
            habitName: habit.name,
            habitID: habit.id,
            todayState: todayState,
            dayIndex: dayIndex,
            theme: .current(),
            weeklyCompletions: weeklyCompletions,
            weeklyTarget: habit.targetDaysPerWeek
        )
    }
}

struct SingleHabitTodayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Single Habit"
    static var description: IntentDescription = "Track one habit for today"

    @Parameter(title: "Habit")
    var habit: HabitEntity?
}

struct SingleHabitTodayView: View {
    let entry: SingleHabitTodayEntry

    private var progressText: String {
        if let target = entry.weeklyTarget {
            return "\(entry.weeklyCompletions)/\(target)"
        }
        return "\(entry.weeklyCompletions)/7"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(entry.habitName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if let habitID = entry.habitID {
                Button(intent: ToggleHabitIntent(habitID: habitID, dayIndex: entry.dayIndex)) {
                    Circle()
                        .fill(entry.theme.color(for: entry.todayState))
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(entry.theme.color(for: .notCompleted))
                    .frame(width: 52, height: 52)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(progressText)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text("this week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetURL(entry.habitID.flatMap { URL(string: "simplehabittracker://habit/\($0.uuidString)") } ?? URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SingleHabitTodayWidget: Widget {
    let kind = "SingleHabitToday"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SingleHabitTodayIntent.self,
            provider: SingleHabitTodayProvider()
        ) { entry in
            SingleHabitTodayView(entry: entry)
        }
        .configurationDisplayName("Habit Check")
        .description("Track one habit for today")
        .supportedFamilies([.systemSmall])
    }
}
