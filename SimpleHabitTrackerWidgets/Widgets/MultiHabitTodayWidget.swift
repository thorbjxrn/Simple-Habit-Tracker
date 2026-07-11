import SwiftUI
import WidgetKit
import AppIntents
import SwiftData

struct HabitTodayData: Identifiable {
    let id: UUID
    let name: String
    let todayState: HabitState
    let weeklyCompletions: Int
    let weeklyTarget: Int?
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
                HabitTodayData(id: UUID(), name: "Exercise", todayState: .completed, weeklyCompletions: 5, weeklyTarget: 5),
                HabitTodayData(id: UUID(), name: "Read", todayState: .notCompleted, weeklyCompletions: 2, weeklyTarget: 7),
                HabitTodayData(id: UUID(), name: "Meditate", todayState: .notCompleted, weeklyCompletions: 3, weeklyTarget: nil),
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

        guard let container = try? SharedModelContainer.create(forWidget: true) else {
            return Entry(date: Date(), habits: [], dayIndex: dayIndex, theme: .current(), isPremium: true)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let allHabits = (try? context.fetch(descriptor)) ?? []

        let selectedIDs = Set(configuration.habits?.map(\.id) ?? [])
        let filtered = selectedIDs.isEmpty ? allHabits : allHabits.filter { selectedIDs.contains($0.id) }

        let startOfWeek = SharedModelContainer.weekStartDate(for: Date())
        let habitData = filtered.map { habit -> HabitTodayData in
            let record = (habit.weekRecords ?? []).first(where: {
                Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
            })
            let state = record?.completedDays[dayIndex] ?? .notCompleted
            let completions = record?.completedDays.filter { $0 == .completed }.count ?? 0
            return HabitTodayData(id: habit.id, name: habit.name, todayState: state, weeklyCompletions: completions, weeklyTarget: habit.targetDaysPerWeek)
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
    let entry: MultiHabitTodayEntry

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
        let habits = Array(entry.habits.prefix(8))
        let useGrid = habits.count > 2

        return Group {
            if useGrid {
                gridLayout(habits: habits)
            } else {
                listLayout(habits: habits)
            }
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func listLayout(habits: [HabitTodayData]) -> some View {
        VStack(spacing: 8) {
            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Button(intent: ToggleHabitIntent(habitID: habit.id, dayIndex: entry.dayIndex)) {
                        Circle()
                            .fill(entry.theme.color(for: habit.todayState))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)

                        Text("\(habit.weeklyCompletions)/\(habit.weeklyTarget ?? 7) this week")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func gridLayout(habits: [HabitTodayData]) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<((habits.count + 1) / 2), id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(habits[rowIndex * 2..<min(rowIndex * 2 + 2, habits.count)]) { habit in
                        HStack(spacing: 8) {
                            Button(intent: ToggleHabitIntent(habitID: habit.id, dayIndex: entry.dayIndex)) {
                                Circle()
                                    .fill(entry.theme.color(for: habit.todayState))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .font(.caption)
                                    .lineLimit(1)

                                Text("\(habit.weeklyCompletions)/\(habit.weeklyTarget ?? 7) this week")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
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
        .supportedFamilies([.systemMedium])
    }
}
