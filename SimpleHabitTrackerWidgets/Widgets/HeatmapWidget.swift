import SwiftUI
import WidgetKit
import SwiftData

struct HeatmapEntry: TimelineEntry {
    let date: Date
    let grid: [[Int]]
    let habitNames: [String]
    let weekLabels: [String]
    let theme: WidgetTheme
    let isPremium: Bool
}

struct HeatmapProvider: TimelineProvider {
    typealias Entry = HeatmapEntry

    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            grid: [[2, 5, 3, 1, 4, 6, 2, 0], [4, 6, 2, 0, 1, 3, 7, 5], [1, 3, 7, 5, 2, 4, 0, 3]],
            habitNames: ["Exercise", "Read", "Meditate"],
            weekLabels: ["31/3", "7/4", "14/4", "21/4", "28/4", "5/5", "12/5", "19/5"],
            theme: .current(),
            isPremium: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> Entry {
        let isPremium = SharedModelContainer.sharedUserDefaults.bool(forKey: "isPremiumCached")
        let theme = WidgetTheme.current()

        guard isPremium, let container = try? SharedModelContainer.create(forWidget: true) else {
            return Entry(date: Date(), grid: [], habitNames: [], weekLabels: [], theme: theme, isPremium: isPremium)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let weekCount = 8
        var weekStarts: [Date] = []
        for i in stride(from: -(weekCount - 1), through: 0, by: 1) {
            if let d = calendar.date(byAdding: .weekOfYear, value: i, to: Date()) {
                weekStarts.append(SharedModelContainer.weekStartDate(for: d))
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        let weekLabels = weekStarts.map { formatter.string(from: $0) }

        var grid: [[Int]] = []
        for habit in habits {
            var row: [Int] = []
            for weekStart in weekStarts {
                let count = habit.weekRecords
                    .first(where: { calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .day) })
                    .map { $0.completedDays.filter { $0 == .completed }.count } ?? 0
                row.append(count)
            }
            grid.append(row)
        }

        return Entry(
            date: Date(),
            grid: grid,
            habitNames: habits.map(\.name),
            weekLabels: weekLabels,
            theme: theme,
            isPremium: true
        )
    }
}

struct HeatmapWidgetView: View {
    let entry: HeatmapEntry

    var body: some View {
        if !entry.isPremium {
            premiumPlaceholder
        } else if entry.habitNames.isEmpty {
            emptyPlaceholder
        } else {
            heatmapGrid
        }
    }

    private var heatmapGrid: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Color.clear.frame(width: 55, height: 10)
                ForEach(Array(entry.weekLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(Array(entry.grid.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 2) {
                    Text(entry.habitNames[rowIndex])
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(width: 55, alignment: .trailing)
                        .lineLimit(1)

                    ForEach(Array(row.enumerated()), id: \.offset) { _, count in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(count: count))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .widgetURL(URL(string: "simplehabittracker://"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func heatColor(count: Int) -> Color {
        switch count {
        case 0: return .gray.opacity(0.15)
        case 1: return entry.theme.completedColor.opacity(0.25)
        case 2: return entry.theme.completedColor.opacity(0.4)
        case 3: return entry.theme.completedColor.opacity(0.55)
        case 4: return entry.theme.completedColor.opacity(0.7)
        case 5: return entry.theme.completedColor.opacity(0.85)
        default: return entry.theme.completedColor
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.3x3")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Add habits to see your heatmap")
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

struct HeatmapWidget: Widget {
    let kind = "Heatmap"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: HeatmapProvider()
        ) { entry in
            HeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Heatmap")
        .description("See your completion patterns at a glance")
        .supportedFamilies([.systemMedium])
    }
}
