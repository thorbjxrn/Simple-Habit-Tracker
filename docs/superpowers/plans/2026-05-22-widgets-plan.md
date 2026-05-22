# WidgetKit Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four interactive home screen widgets (single-habit-today, single-habit-week, multi-habit-today, heatmap) with themed colors and App Intents for toggling completion state.

**Architecture:** A new WidgetKit extension shares the SwiftData store via an App Group. Shared code (models, theme, data access) is added to both targets. Each widget uses `AppIntentConfiguration` with entity queries for habit selection. Interactive `Button`s in widget views toggle state via `ToggleHabitIntent`.

**Tech Stack:** WidgetKit, AppIntents, SwiftData, SwiftUI, App Groups

---

## File Structure

### Shared code (added to both app target and widget extension target)

These files already exist and will be added to the widget extension's target membership:

- `SimpleHabitTracker/Models/HabitModel.swift` — `Habit` SwiftData model
- `SimpleHabitTracker/Models/WeekRecord.swift` — `WeekRecord` SwiftData model
- `SimpleHabitTracker/Models/HabitState.swift` — `HabitState` enum
- `SimpleHabitTracker/Utilities/ThemeManager.swift` — `AppTheme` enum + `DynamicPalette`

New shared file:

- `SimpleHabitTracker/Shared/SharedModelContainer.swift` — App Group-aware `ModelContainer` factory + lightweight data access helpers

### Widget extension (new target: `SimpleHabitTrackerWidgets`)

- `SimpleHabitTrackerWidgets/WidgetBundle.swift` — `WidgetBundle` registering all four widgets
- `SimpleHabitTrackerWidgets/Intents/HabitEntity.swift` — `AppEntity` + `EntityQuery` for habit picker
- `SimpleHabitTrackerWidgets/Intents/ToggleHabitIntent.swift` — `AppIntent` that cycles a day's state
- `SimpleHabitTrackerWidgets/Widgets/SingleHabitTodayWidget.swift` — Small widget: one habit, today's dot
- `SimpleHabitTrackerWidgets/Widgets/SingleHabitWeekWidget.swift` — Medium widget: one habit, 7 day dots
- `SimpleHabitTrackerWidgets/Widgets/MultiHabitTodayWidget.swift` — Medium/Large widget: selected habits, today's dot each
- `SimpleHabitTrackerWidgets/Widgets/HeatmapWidget.swift` — Large widget: completion heatmap grid
- `SimpleHabitTrackerWidgets/Helpers/WidgetTheme.swift` — Resolves theme colors from shared `UserDefaults` for widget views
- `SimpleHabitTrackerWidgets/Helpers/WidgetDateHelpers.swift` — Day index, day labels, week start date utilities

### Modified existing files

- `SimpleHabitTracker/SimpleHabitTrackerApp.swift` — Use `SharedModelContainer`, reload widget timelines on foreground
- `SimpleHabitTracker/SimpleHabitTracker.entitlements` — Add App Group capability
- `SimpleHabitTracker/PurchaseManager.swift` — Write `isPremiumCached` to shared `UserDefaults`
- `SimpleHabitTracker/HabitTrackerView.swift` — Reload widget timelines after toggling a day

---

## Task 1: App Group + Shared Model Container

Set up the App Group so both processes can access the same SwiftData store and UserDefaults.

**Files:**
- Create: `SimpleHabitTracker/Shared/SharedModelContainer.swift`
- Modify: `SimpleHabitTracker/SimpleHabitTracker.entitlements`
- Modify: `SimpleHabitTracker/SimpleHabitTrackerApp.swift`
- Modify: `SimpleHabitTracker/PurchaseManager.swift`

- [ ] **Step 1: Add App Group to entitlements**

Edit `SimpleHabitTracker/SimpleHabitTracker.entitlements` to add:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.thorbjxrn.SimpleHabitTracker</string>
</array>
```

The full file becomes:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.thorbjxrn.SimpleHabitTracker</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.thorbjxrn.SimpleHabitTracker</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 2: Create SharedModelContainer**

Create `SimpleHabitTracker/Shared/SharedModelContainer.swift`:

```swift
import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.thorbjxrn.SimpleHabitTracker"

    static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func create() throws -> ModelContainer {
        let syncEnabled = sharedUserDefaults.bool(forKey: "iCloudSyncEnabled")
        let isPremium = sharedUserDefaults.bool(forKey: "isPremiumCached")

        let config: ModelConfiguration
        if syncEnabled && isPremium {
            config = ModelConfiguration(
                url: storeURL,
                cloudKitDatabase: .private("iCloud.thorbjxrn.SimpleHabitTracker")
            )
        } else {
            config = ModelConfiguration(
                url: storeURL,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: Habit.self, configurations: config)
    }

    private static var storeURL: URL {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )!
        return containerURL.appendingPathComponent("SimpleHabitTracker.store")
    }

    // MARK: - Widget Data Helpers

    static func todayDayIndex() -> Int {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let firstWeekday = calendar.firstWeekday
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday - firstWeekday + 7) % 7
    }

    static func weekStartDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func currentWeekRecord(for habit: Habit, context: ModelContext) -> WeekRecord {
        let startOfWeek = weekStartDate(for: Date())
        let calendar = Calendar.current

        if let existing = habit.weekRecords.first(where: {
            calendar.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
        }) {
            return existing
        }

        let record = WeekRecord(weekStartDate: startOfWeek)
        context.insert(record)
        habit.weekRecords.append(record)
        try? context.save()
        return record
    }

    static func toggleDay(habitID: UUID, dayIndex: Int) {
        guard let container = try? create() else { return }
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Habit>()
        guard let habits = try? context.fetch(descriptor),
              let habit = habits.first(where: { $0.id == habitID }) else { return }

        let record = currentWeekRecord(for: habit, context: context)
        guard dayIndex >= 0 && dayIndex < record.completedDays.count else { return }

        var days = record.completedDays
        switch days[dayIndex] {
        case .notCompleted: days[dayIndex] = .completed
        case .completed: days[dayIndex] = .failed
        case .failed: days[dayIndex] = .notCompleted
        }
        record.completedDays = days
        try? context.save()
    }

    static func dayLabels() -> [String] {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday
        var reordered: [String] = []
        for i in 0..<7 {
            let index = (firstWeekday - 1 + i) % 7
            reordered.append(symbols[index])
        }
        return reordered
    }
}
```

- [ ] **Step 3: Migrate existing data on first launch**

In `SimpleHabitTrackerApp.swift`, the existing store is at the default SwiftData location. On first launch after this update, the store needs to be at the App Group URL. Add a one-time migration before creating the container.

Add this static method to `SharedModelContainer`:

```swift
static func migrateStoreToAppGroupIfNeeded() {
    let fileManager = FileManager.default
    let appGroupURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupID
    )!
    let newStoreURL = appGroupURL.appendingPathComponent("SimpleHabitTracker.store")

    guard !fileManager.fileExists(atPath: newStoreURL.path) else { return }

    let defaultURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("default.store")

    guard fileManager.fileExists(atPath: defaultURL.path) else { return }

    let extensions = ["", "-wal", "-shm"]
    for ext in extensions {
        let src = URL(fileURLWithPath: defaultURL.path + ext)
        let dst = URL(fileURLWithPath: newStoreURL.path + ext)
        try? fileManager.copyItem(at: src, to: dst)
    }
}
```

- [ ] **Step 4: Update SimpleHabitTrackerApp to use SharedModelContainer**

Replace the `init()` in `SimpleHabitTrackerApp.swift`:

```swift
init() {
    let pm = PurchaseManager()
    _purchaseManager = State(initialValue: pm)
    _adManager = State(initialValue: AdManager(purchaseManager: pm))

    SharedModelContainer.migrateStoreToAppGroupIfNeeded()

    do {
        modelContainer = try SharedModelContainer.create()
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    MobileAds.shared.start()

    try? Tips.configure()
}
```

- [ ] **Step 5: Migrate UserDefaults to shared suite**

In `PurchaseManager.swift`, update `updatePremiumStatus` to write to both standard and shared:

```swift
private func updatePremiumStatus(_ newValue: Bool) {
    isPremium = newValue
    UserDefaults.standard.set(newValue, forKey: Self.isPremiumKey)
    SharedModelContainer.sharedUserDefaults.set(newValue, forKey: Self.isPremiumKey)
}
```

Also update `SimpleHabitTrackerApp.init()` to read from shared and sync the `iCloudSyncEnabled` flag there too. Add after `SharedModelContainer.migrateStoreToAppGroupIfNeeded()`:

```swift
// Sync settings to shared UserDefaults for widget access
let shared = SharedModelContainer.sharedUserDefaults
shared.set(UserDefaults.standard.bool(forKey: "isPremiumCached"), forKey: "isPremiumCached")
shared.set(UserDefaults.standard.bool(forKey: "iCloudSyncEnabled"), forKey: "iCloudSyncEnabled")
shared.set(UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.defaultTheme.rawValue, forKey: "selectedTheme")
```

- [ ] **Step 6: Reload widget timelines on foreground and after toggle**

In `SimpleHabitTrackerApp.swift`, add to the `WindowGroup` body:

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    WidgetCenter.shared.reloadAllTimelines()
}
```

Add `import WidgetKit` at the top of the file.

In `HabitTrackerView.swift`, in the `onToggle` closure (line ~245), add after `updateStreakCache()`:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

Add `import WidgetKit` at the top of `HabitTrackerView.swift`.

- [ ] **Step 7: Build and verify the app still works**

Run: `xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add SimpleHabitTracker/Shared/SharedModelContainer.swift SimpleHabitTracker/SimpleHabitTracker.entitlements SimpleHabitTracker/SimpleHabitTrackerApp.swift SimpleHabitTracker/PurchaseManager.swift SimpleHabitTracker/HabitTrackerView.swift
git commit -m "feat: add App Group and shared model container for widget data access"
```

---

## Task 2: Widget Extension Scaffold + Habit Entity

Create the widget extension target and the `AppEntity`/`EntityQuery` that powers habit selection in all widget configurations.

**Files:**
- Create: `SimpleHabitTrackerWidgets/WidgetBundle.swift`
- Create: `SimpleHabitTrackerWidgets/Intents/HabitEntity.swift`
- Create: `SimpleHabitTrackerWidgets/Helpers/WidgetTheme.swift`
- Create: `SimpleHabitTrackerWidgets/Helpers/WidgetDateHelpers.swift`
- Create: `SimpleHabitTrackerWidgets/SimpleHabitTrackerWidgets.entitlements`

- [ ] **Step 1: Create the widget extension directory structure**

```bash
mkdir -p SimpleHabitTrackerWidgets/Intents
mkdir -p SimpleHabitTrackerWidgets/Widgets
mkdir -p SimpleHabitTrackerWidgets/Helpers
```

- [ ] **Step 2: Create the widget extension entitlements**

Create `SimpleHabitTrackerWidgets/SimpleHabitTrackerWidgets.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.thorbjxrn.SimpleHabitTracker</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Create WidgetTheme helper**

Create `SimpleHabitTrackerWidgets/Helpers/WidgetTheme.swift`:

```swift
import SwiftUI

struct WidgetTheme {
    let completedColor: Color
    let failedColor: Color
    let notCompletedColor: Color

    static func current() -> WidgetTheme {
        let themeRaw = SharedModelContainer.sharedUserDefaults.string(forKey: "selectedTheme")
            ?? AppTheme.defaultTheme.rawValue
        let theme = AppTheme.from(rawValue: themeRaw)
        return WidgetTheme(
            completedColor: theme.completedColor,
            failedColor: theme.failedColor,
            notCompletedColor: theme.notCompletedColor
        )
    }

    func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted: return notCompletedColor
        case .completed: return completedColor
        case .failed: return failedColor
        }
    }
}
```

- [ ] **Step 4: Create WidgetDateHelpers**

Create `SimpleHabitTrackerWidgets/Helpers/WidgetDateHelpers.swift`:

```swift
import Foundation

enum WidgetDateHelpers {
    static var todayDayIndex: Int {
        SharedModelContainer.todayDayIndex()
    }

    static var dayLabels: [String] {
        SharedModelContainer.dayLabels()
    }

    static func weekStartDate(for date: Date = Date()) -> Date {
        SharedModelContainer.weekStartDate(for: date)
    }
}
```

- [ ] **Step 5: Create HabitEntity and HabitQuery**

Create `SimpleHabitTrackerWidgets/Intents/HabitEntity.swift`:

```swift
import AppIntents
import SwiftData

struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static var defaultQuery = HabitQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let container = try SharedModelContainer.create()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = (try? context.fetch(descriptor)) ?? []
        return habits
            .filter { identifiers.contains($0.id) }
            .map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        let container = try SharedModelContainer.create()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = (try? context.fetch(descriptor)) ?? []
        return habits.map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> HabitEntity? {
        try? await suggestedEntities().first
    }
}
```

- [ ] **Step 6: Create the WidgetBundle (placeholder — widgets added in later tasks)**

Create `SimpleHabitTrackerWidgets/WidgetBundle.swift`:

```swift
import SwiftUI
import WidgetKit

@main
struct SimpleHabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleHabitTodayWidget()
    }
}
```

- [ ] **Step 7: Add the widget extension target to the Xcode project**

This step must be done in Xcode: File → New → Target → Widget Extension.

- Name: `SimpleHabitTrackerWidgets`
- Bundle ID: `thorbjxrn.SimpleHabitTracker.Widgets`
- Team: `228DC29L7W`
- Deployment target: iOS 17.0
- Uncheck "Include Configuration App Intent" (we provide our own)
- Delete the auto-generated files Xcode creates and replace with the files from this plan

Then configure target membership:
- Add `SimpleHabitTracker/Models/HabitModel.swift` to the widget target
- Add `SimpleHabitTracker/Models/WeekRecord.swift` to the widget target
- Add `SimpleHabitTracker/Models/HabitState.swift` to the widget target
- Add `SimpleHabitTracker/Utilities/ThemeManager.swift` to the widget target
- Add `SimpleHabitTracker/Shared/SharedModelContainer.swift` to the widget target
- Set the widget entitlements file in Build Settings → Code Signing Entitlements

- [ ] **Step 8: Commit**

```bash
git add SimpleHabitTrackerWidgets/ SimpleHabitTracker.xcodeproj/
git commit -m "feat: scaffold widget extension with habit entity and theme helpers"
```

---

## Task 3: ToggleHabitIntent

The interactive intent that toggles a habit day's completion state from widget taps.

**Files:**
- Create: `SimpleHabitTrackerWidgets/Intents/ToggleHabitIntent.swift`

- [ ] **Step 1: Create ToggleHabitIntent**

Create `SimpleHabitTrackerWidgets/Intents/ToggleHabitIntent.swift`:

```swift
import AppIntents
import WidgetKit

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description: IntentDescription = "Toggle a habit's completion for today"

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Day Index")
    var dayIndex: Int

    init() {}

    init(habitID: UUID, dayIndex: Int) {
        self.habitID = habitID.uuidString
        self.dayIndex = dayIndex
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else {
            return .result()
        }
        SharedModelContainer.toggleDay(habitID: uuid, dayIndex: dayIndex)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add SimpleHabitTrackerWidgets/Intents/ToggleHabitIntent.swift
git commit -m "feat: add ToggleHabitIntent for interactive widget toggles"
```

---

## Task 4: Single Habit Today Widget (Small — Free)

The free-tier widget showing one habit with today's completion dot.

**Files:**
- Create: `SimpleHabitTrackerWidgets/Widgets/SingleHabitTodayWidget.swift`

- [ ] **Step 1: Create SingleHabitTodayWidget**

Create `SimpleHabitTrackerWidgets/Widgets/SingleHabitTodayWidget.swift`:

```swift
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
            theme: .current()
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
              let container = try? SharedModelContainer.create() else {
            return Entry(
                date: Date(),
                habitName: "Select a habit",
                habitID: nil,
                todayState: .notCompleted,
                dayIndex: WidgetDateHelpers.todayDayIndex,
                theme: .current()
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
                theme: .current()
            )
        }

        let record = SharedModelContainer.currentWeekRecord(for: habit, context: context)
        let todayState = record.completedDays[dayIndex]

        return Entry(
            date: Date(),
            habitName: habit.name,
            habitID: habit.id,
            todayState: todayState,
            dayIndex: dayIndex,
            theme: .current()
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

    var body: some View {
        VStack(spacing: 12) {
            Text(entry.habitName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let habitID = entry.habitID {
                Button(intent: ToggleHabitIntent(habitID: habitID, dayIndex: entry.dayIndex)) {
                    Circle()
                        .fill(entry.theme.color(for: entry.todayState))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(entry.theme.color(for: .notCompleted))
                    .frame(width: 44, height: 44)
            }
        }
        .widgetURL(URL(string: "simplehabittracker://"))
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
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTrackerWidgets -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SimpleHabitTrackerWidgets/Widgets/SingleHabitTodayWidget.swift
git commit -m "feat: add single habit today widget (small, free tier)"
```

---

## Task 5: Single Habit Week Widget (Medium — Premium)

Shows one habit with all 7 day dots for the current week. Only today is tappable.

**Files:**
- Create: `SimpleHabitTrackerWidgets/Widgets/SingleHabitWeekWidget.swift`
- Modify: `SimpleHabitTrackerWidgets/WidgetBundle.swift`

- [ ] **Step 1: Create SingleHabitWeekWidget**

Create `SimpleHabitTrackerWidgets/Widgets/SingleHabitWeekWidget.swift`:

```swift
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

        let record = SharedModelContainer.currentWeekRecord(for: habit, context: context)

        return Entry(
            date: Date(),
            habitName: habit.name,
            habitID: habit.id,
            days: record.completedDays,
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
```

- [ ] **Step 2: Update WidgetBundle**

Update `SimpleHabitTrackerWidgets/WidgetBundle.swift`:

```swift
import SwiftUI
import WidgetKit

@main
struct SimpleHabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleHabitTodayWidget()
        SingleHabitWeekWidget()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTrackerWidgets -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTrackerWidgets/Widgets/SingleHabitWeekWidget.swift SimpleHabitTrackerWidgets/WidgetBundle.swift
git commit -m "feat: add single habit week widget (medium, premium)"
```

---

## Task 6: Multi-Habit Today Widget (Medium + Large — Premium)

Shows multiple user-selected habits with today's dot for each.

**Files:**
- Create: `SimpleHabitTrackerWidgets/Widgets/MultiHabitTodayWidget.swift`
- Modify: `SimpleHabitTrackerWidgets/WidgetBundle.swift`

- [ ] **Step 1: Create MultiHabitTodayWidget**

Create `SimpleHabitTrackerWidgets/Widgets/MultiHabitTodayWidget.swift`:

```swift
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
```

- [ ] **Step 2: Update WidgetBundle**

Update `SimpleHabitTrackerWidgets/WidgetBundle.swift`:

```swift
import SwiftUI
import WidgetKit

@main
struct SimpleHabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleHabitTodayWidget()
        SingleHabitWeekWidget()
        MultiHabitTodayWidget()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTrackerWidgets -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTrackerWidgets/Widgets/MultiHabitTodayWidget.swift SimpleHabitTrackerWidgets/WidgetBundle.swift
git commit -m "feat: add multi-habit today widget (medium/large, premium)"
```

---

## Task 7: Heatmap Widget (Large — Premium)

Read-only heatmap grid showing aggregate completion data.

**Files:**
- Create: `SimpleHabitTrackerWidgets/Widgets/HeatmapWidget.swift`
- Modify: `SimpleHabitTrackerWidgets/WidgetBundle.swift`

- [ ] **Step 1: Create HeatmapWidget**

Create `SimpleHabitTrackerWidgets/Widgets/HeatmapWidget.swift`:

```swift
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
            grid: [[2, 5, 3, 1], [4, 6, 2, 0], [1, 3, 7, 5]],
            habitNames: ["Exercise", "Read", "Meditate"],
            weekLabels: ["28/4", "5/5", "12/5", "19/5"],
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

        guard isPremium, let container = try? SharedModelContainer.create() else {
            return Entry(date: Date(), grid: [], habitNames: [], weekLabels: [], theme: theme, isPremium: isPremium)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        let habits = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let weekCount = 12
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
        VStack(alignment: .leading, spacing: 3) {
            Text("Heatmap")
                .font(.headline)
                .padding(.bottom, 2)

            // Week labels header
            HStack(spacing: 3) {
                Color.clear.frame(width: 60, height: 10)
                ForEach(Array(entry.weekLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid rows
            ForEach(Array(entry.grid.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 3) {
                    Text(entry.habitNames[rowIndex])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)
                        .lineLimit(1)

                    ForEach(Array(row.enumerated()), id: \.offset) { _, count in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(count: count))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(heatColor(count: level * 2))
                        .frame(width: 8, height: 8)
                }
                Text("More")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
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
        .supportedFamilies([.systemLarge])
    }
}
```

- [ ] **Step 2: Update WidgetBundle — final version**

Update `SimpleHabitTrackerWidgets/WidgetBundle.swift`:

```swift
import SwiftUI
import WidgetKit

@main
struct SimpleHabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleHabitTodayWidget()
        SingleHabitWeekWidget()
        MultiHabitTodayWidget()
        HeatmapWidget()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTrackerWidgets -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTrackerWidgets/Widgets/HeatmapWidget.swift SimpleHabitTrackerWidgets/WidgetBundle.swift
git commit -m "feat: add heatmap widget (large, premium)"
```

---

## Task 8: Update Backlog + Final Build Verification

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Update BACKLOG.md**

Mark the widget item as done and remove it from the Medium section:

Replace:
```
- [ ] Widgets
```

with:
```
- [x] ~~Widgets~~ — shipped: 4 WidgetKit widgets (single today free, week/multi/heatmap premium)
```

- [ ] **Step 2: Full build of both targets**

Run:
```bash
xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
xcodebuild -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTrackerWidgets -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

Expected: Both `** BUILD SUCCEEDED **`

- [ ] **Step 3: Test on simulator**

- Install the app on the simulator
- Long-press the home screen → add widget → search "Simple Habit"
- Verify all four widgets appear in the gallery
- Add the small widget, configure a habit, tap the dot to toggle
- Add the medium week widget, verify 7 dots render with day labels
- Verify premium lock placeholder shows when not premium

- [ ] **Step 4: Commit**

```bash
git add BACKLOG.md
git commit -m "chore: mark widgets as shipped in backlog"
```
