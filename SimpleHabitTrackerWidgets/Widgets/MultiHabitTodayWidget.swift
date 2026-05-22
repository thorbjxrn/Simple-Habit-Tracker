import SwiftUI
import WidgetKit
import AppIntents
import SwiftData

struct HabitTodayData: Identifiable {
    let id: UUID
    let name: String
    let todayState: HabitState
}

struct MultiHabitTodayEntry: TimelineEntry {
    let date: Date
    let habits: [HabitTodayData]
    let dayIndex: Int
    let theme: WidgetTheme
    let isPremium: Bool
}

struct MultiHabitTodayProvider: AppIntentTimelineProvider {
    typealias Entry = MultiHabitTodayEntry
    typealias Intent = MultiHabitTodayIntent

    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            habits: [
                HabitTodayData(id: UUID(), name: "Exercise", todayState: .completed),
                HabitTodayData(id: UUID(), name: "Read", todayState: .notCompleted),
                HabitTodayData(id: UUID(), name: "Meditate", todayState: .notCompleted),
            ],
            dayIndex: 0,
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
        let dayIndex = WidgetDateHelpers.todayDayIndex

        guard isPremium else {
            return Entry(date: Date(), habits: [], dayIndex: dayIndex, theme: .current(), isPremium: false)
        }

        guard let container = try? SharedModelContainer.create() else {
            return Entry(date: Date(), habits: [], dayIndex: dayIndex, theme: .current(), isPremium: true)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let allHabits = (try? context.fetch(descriptor)) ?? []

        let selectedIDs = Set(configuration.habits?.map(\.id) ?? [])
        let filtered = selectedIDs.isEmpty ? allHabits : allHabits.filter { selectedIDs.contains($0.id) }

        let habitData = filtered.map { habit -> HabitTodayData in
            let record = SharedModelContainer.currentWeekRecord(for: habit, context: context)
            let state = record.completedDays[dayIndex]
            return HabitTodayData(id: habit.id, name: habit.name, todayState: state)
        }

        return Entry(date: Date(), habits: habitData, dayIndex: dayIndex, theme: .current(), isPremium: true)
    }
}

struct MultiHabitTodayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Habits Today"
    static var description: IntentDescription = "Track multiple habits for today"

    @Parameter(title: "Habits")
    var habits: [HabitEntity]?
}

struct MultiHabitTodayView: View {
    @Environment(\.widgetFamily) var family
    let entry: MultiHabitTodayEntry

    private var maxHabits: Int {
        family == .systemLarge ? 8 : 4
    }

    var body: some View {
        if !entry.isPremium {
            premiumPlaceholder
        } else if entry.habits.isEmpty {
            emptyPlaceholder
        } else {
            habitList
        }
    }

    private var habitList: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 8 : 6) {
            ForEach(entry.habits.prefix(maxHabits)) { habit in
                HStack(spacing: 10) {
                    Button(intent: ToggleHabitIntent(habitID: habit.id, dayIndex: entry.dayIndex)) {
                        Circle()
                            .fill(entry.theme.color(for: habit.todayState))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Text(habit.name)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Select habits to track")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
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

struct MultiHabitTodayWidget: Widget {
    let kind = "MultiHabitToday"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MultiHabitTodayIntent.self,
            provider: MultiHabitTodayProvider()
        ) { entry in
            MultiHabitTodayView(entry: entry)
        }
        .configurationDisplayName("Habits Today")
        .description("Track multiple habits at a glance")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
