import SwiftUI
import WidgetKit
import AppIntents
import SwiftData

struct SingleHabitWeekEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitID: UUID?
    let days: [HabitState]
    let dayLabels: [String]
    let todayIndex: Int
    let theme: WidgetTheme
    let isPremium: Bool
}

struct SingleHabitWeekProvider: AppIntentTimelineProvider {
    typealias Entry = SingleHabitWeekEntry
    typealias Intent = SingleHabitWeekIntent

    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            habitName: "Habit",
            habitID: nil,
            days: Array(repeating: .notCompleted, count: 7),
            dayLabels: WidgetDateHelpers.dayLabels,
            todayIndex: WidgetDateHelpers.todayDayIndex,
            theme: .current(),
            isPremium: true
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
        let isPremium = SharedModelContainer.sharedUserDefaults.bool(forKey: "isPremiumCached")
        let todayIndex = WidgetDateHelpers.todayDayIndex

        guard isPremium else {
            return Entry(
                date: Date(),
                habitName: "Premium Feature",
                habitID: nil,
                days: Array(repeating: .notCompleted, count: 7),
                dayLabels: WidgetDateHelpers.dayLabels,
                todayIndex: todayIndex,
                theme: .current(),
                isPremium: false
            )
        }

        guard let selectedHabit = configuration.habit,
              let container = try? SharedModelContainer.create() else {
            return Entry(
                date: Date(),
                habitName: "Select a habit",
                habitID: nil,
                days: Array(repeating: .notCompleted, count: 7),
                dayLabels: WidgetDateHelpers.dayLabels,
                todayIndex: todayIndex,
                theme: .current(),
                isPremium: true
            )
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? context.fetch(descriptor)) ?? []

        guard let habit = habits.first(where: { $0.id == selectedHabit.id }) else {
            return Entry(
                date: Date(),
                habitName: selectedHabit.name,
                habitID: selectedHabit.id,
                days: Array(repeating: .notCompleted, count: 7),
                dayLabels: WidgetDateHelpers.dayLabels,
                todayIndex: todayIndex,
                theme: .current(),
                isPremium: true
            )
        }

        let startOfWeek = SharedModelContainer.weekStartDate(for: Date())
        let record = habit.weekRecords.first(where: {
            Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
        })

        return Entry(
            date: Date(),
            habitName: habit.name,
            habitID: habit.id,
            days: record?.completedDays ?? Array(repeating: .notCompleted, count: 7),
            dayLabels: WidgetDateHelpers.dayLabels,
            todayIndex: todayIndex,
            theme: .current(),
            isPremium: true
        )
    }
}

struct SingleHabitWeekIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Habit Week"
    static var description: IntentDescription = "Track one habit for the whole week"

    @Parameter(title: "Habit")
    var habit: HabitEntity?
}

struct SingleHabitWeekView: View {
    let entry: SingleHabitWeekEntry

    var body: some View {
        if !entry.isPremium {
            premiumPlaceholder
        } else {
            weekContent
        }
    }

    private var weekContent: some View {
        VStack(spacing: 8) {
            Text(entry.habitName)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text(entry.dayLabels[index])
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        if index == entry.todayIndex, let habitID = entry.habitID {
                            Button(intent: ToggleHabitIntent(habitID: habitID, dayIndex: index)) {
                                dayDot(for: entry.days[index], isToday: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            dayDot(for: entry.days[index], isToday: false)
                        }
                    }
                }
            }
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func dayDot(for state: HabitState, isToday: Bool) -> some View {
        Circle()
            .fill(entry.theme.color(for: state))
            .frame(width: 28, height: 28)
            .overlay {
                if isToday {
                    Circle()
                        .strokeBorder(.primary.opacity(0.3), lineWidth: 1.5)
                }
            }
    }

    private var premiumPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Upgrade to Premium")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SingleHabitWeekWidget: Widget {
    let kind = "SingleHabitWeek"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SingleHabitWeekIntent.self,
            provider: SingleHabitWeekProvider()
        ) { entry in
            SingleHabitWeekView(entry: entry)
        }
        .configurationDisplayName("Habit Week")
        .description("See your full week for one habit")
        .supportedFamilies([.systemMedium])
    }
}
