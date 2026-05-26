# App Store Screenshot Gallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `#if DEBUG` screenshot preview system with three A/B/C treatments for App Store Connect product page optimization.

**Architecture:** Single file `ScreenshotPreviews.swift` containing all mock data, six screenshot views, three frame styles, a debug gallery, and Xcode previews. No SwiftData or ViewModel dependencies — purely static SwiftUI. One small modification to `SettingsView.swift` to add the gallery entry point.

**Tech Stack:** SwiftUI, `#if DEBUG`, `#Preview` macros

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `SimpleHabitTracker/Views/ScreenshotPreviews.swift` | Create | All mock data, screenshot views, frame styles, gallery, previews |
| `SimpleHabitTracker/Views/SettingsView.swift` | Modify (lines 226-248) | Add "Screenshot Gallery" button to debug section |

---

### Task 1: Mock Data Foundation

**Files:**
- Create: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

Create the file with `#if DEBUG` wrapper, mock data types, and all three treatment datasets.

- [ ] **Step 1: Create the file with mock data types and Treatment A dataset**

```swift
#if DEBUG
import SwiftUI

// MARK: - Mock Data Types

struct MockHabit: Identifiable {
    let id = UUID()
    let name: String
    let days: [HabitState]
    let streak: Int
    let target: Int?

    var completedCount: Int {
        days.filter { $0 == .completed }.count
    }
}

struct MockStats {
    let currentStreak: Int
    let bestWeek: Int
    let completionRate: Int
    let totalCompletions: Int
}

struct MockTreatment {
    let habits: [MockHabit]
    let stats: MockStats
    let heatmapGrid: [[Int]]
}

// MARK: - Day shorthand

private let d = HabitState.completed
private let f = HabitState.failed
private let n = HabitState.notCompleted

// MARK: - Shared Helpers

func screenshotColor(for state: HabitState, theme: AppTheme) -> Color {
    switch state {
    case .notCompleted: return theme.notCompletedColor
    case .completed: return theme.completedColor
    case .failed: return theme.failedColor
    }
}

// MARK: - Treatment A — "The Everyday User"

let treatmentA = MockTreatment(
    habits: [
        MockHabit(name: "Morning Run",      days: [d, d, d, f, d, d, n], streak: 3,  target: 5),
        MockHabit(name: "Read 10 Pages",    days: [d, d, d, d, d, d, n], streak: 6,  target: 6),
        MockHabit(name: "Meditate",          days: [d, f, d, d, f, d, n], streak: 1,  target: 5),
        MockHabit(name: "No Phone in Bed",   days: [d, d, f, d, d, d, n], streak: 2,  target: nil),
        MockHabit(name: "Practice Guitar",   days: [f, d, f, d, f, d, n], streak: 0,  target: 4),
    ],
    stats: MockStats(currentStreak: 6, bestWeek: 32, completionRate: 78, totalCompletions: 147),
    heatmapGrid: [
        [3, 3, 4, 3, 5, 4, 5, 5],
        [5, 4, 5, 6, 5, 6, 6, 6],
        [2, 3, 2, 3, 3, 4, 3, 4],
        [4, 3, 4, 5, 4, 4, 5, 5],
        [1, 2, 1, 2, 3, 2, 3, 3],
    ]
)

// MARK: - Treatment B — "The Streak Machine"

let treatmentB = MockTreatment(
    habits: [
        MockHabit(name: "Gym",              days: [d, d, d, d, d, d, n], streak: 8,  target: 6),
        MockHabit(name: "Read 30 Minutes",  days: [d, d, d, d, d, d, n], streak: 12, target: 6),
        MockHabit(name: "Journal",           days: [d, d, d, d, d, f, n], streak: 5,  target: 6),
        MockHabit(name: "Cold Shower",       days: [d, d, d, d, d, d, n], streak: 4,  target: 6),
        MockHabit(name: "Cook at Home",      days: [d, d, f, d, d, d, n], streak: 3,  target: 5),
    ],
    stats: MockStats(currentStreak: 12, bestWeek: 34, completionRate: 91, totalCompletions: 312),
    heatmapGrid: [
        [5, 6, 6, 5, 6, 6, 7, 6],
        [6, 7, 6, 7, 6, 7, 6, 6],
        [4, 5, 5, 6, 5, 6, 5, 5],
        [5, 5, 6, 6, 6, 6, 7, 6],
        [3, 4, 4, 5, 4, 5, 5, 5],
    ]
)

// MARK: - Treatment C — "The Quick Check"

let treatmentC = MockTreatment(
    habits: [
        MockHabit(name: "Drink Water",      days: [d, d, d, d, d, d, n], streak: 4,  target: nil),
        MockHabit(name: "Take Vitamins",    days: [d, d, d, f, d, d, n], streak: 2,  target: nil),
        MockHabit(name: "Stretch",           days: [d, f, d, d, d, d, n], streak: 1,  target: 5),
        MockHabit(name: "Walk 10k Steps",   days: [d, d, d, d, f, d, n], streak: 3,  target: 5),
        MockHabit(name: "No Snooze",         days: [f, d, d, d, d, d, n], streak: 2,  target: nil),
    ],
    stats: MockStats(currentStreak: 4, bestWeek: 24, completionRate: 82, totalCompletions: 89),
    heatmapGrid: [
        [5, 4, 5, 6, 5, 5, 6, 6],
        [4, 3, 4, 4, 5, 4, 5, 5],
        [3, 2, 3, 4, 3, 4, 4, 4],
        [4, 4, 3, 5, 4, 4, 4, 5],
        [2, 3, 3, 4, 4, 4, 5, 5],
    ]
)

#endif
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add mock data foundation for screenshot previews"
```

---

### Task 2: Frame Styles and ScreenshotFrame

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

Add the `FrameStyle` enum and `ScreenshotFrame` wrapper view that all screenshot content is wrapped in.

- [ ] **Step 1: Add FrameStyle and ScreenshotFrame above the `#endif`**

```swift
// MARK: - Frame Styles

enum FrameStyle: String, CaseIterable, Identifiable {
    case dark, light, gradient

    var id: String { rawValue }

    var background: AnyShapeStyle {
        switch self {
        case .dark:
            AnyShapeStyle(Color(.sRGB, red: 0.07, green: 0.07, blue: 0.10))
        case .light:
            AnyShapeStyle(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97))
        case .gradient:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color(.sRGB, red: 0.20, green: 0.78, blue: 0.35),
                             Color(.sRGB, red: 0.19, green: 0.69, blue: 0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    var headlineColor: Color {
        switch self {
        case .dark, .gradient: .white
        case .light: Color(.sRGB, red: 0.11, green: 0.11, blue: 0.12)
        }
    }

    var subtitleColor: Color {
        switch self {
        case .dark: .white.opacity(0.7)
        case .light: Color(.sRGB, red: 0.43, green: 0.43, blue: 0.45)
        case .gradient: .white.opacity(0.8)
        }
    }

    var cardBorder: some ShapeStyle {
        switch self {
        case .dark: AnyShapeStyle(.white.opacity(0.08))
        case .light: AnyShapeStyle(.clear)
        case .gradient: AnyShapeStyle(.white.opacity(0.15))
        }
    }

    var cardShadowRadius: CGFloat {
        switch self {
        case .dark: 30
        case .light: 20
        case .gradient: 30
        }
    }
}

// MARK: - Screenshot Frame

struct ScreenshotFrame<Content: View>: View {
    let headline: String
    var subtitle: String? = nil
    let style: FrameStyle
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text(headline)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(style.headlineColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(style.subtitleColor)
                    .padding(.top, 6)
            }

            Spacer().frame(height: 28)

            content
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(style == .light ? 0 : (style == .dark ? 0.08 : 0.15)), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.6), radius: style.cardShadowRadius, y: 10)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(style.background.ignoresSafeArea())
    }
}
```

- [ ] **Step 2: Add a simple preview to verify the frame renders**

```swift
#Preview("Frame - Dark", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotFrame(headline: "Test Headline", subtitle: "Test subtitle", style: .dark) {
        Color.gray.frame(height: 600)
    }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add FrameStyle enum and ScreenshotFrame wrapper"
```

---

### Task 3: Screenshot Screen 1 — Hero Habit List

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

Build the hero habit list screenshot view. This is the most complex screen — it recreates the main tracker layout with static data.

- [ ] **Step 1: Add the ScreenshotHabitList view**

```swift
// MARK: - Screen 1: Hero Habit List

struct ScreenshotHabitList: View {
    let data: MockTreatment
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekNavHeader

                List {
                    Section {
                        ForEach(data.habits) { habit in
                            mockHabitRow(habit)
                        }
                    } header: {
                        dayOfWeekHeader
                    }
                }
                .listStyle(.plain)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private var weekNavHeader: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundStyle(.primary)
            Spacer()
            Text("This Week")
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.title2)
                .foregroundStyle(.gray.opacity(0.3))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            let labels = localizedDayLabels()
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func mockHabitRow(_ habit: MockHabit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(habit.name)
                    .font(.headline)

                Spacer()

                if habit.streak >= 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(habit.streak)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                }

                if let target = habit.target {
                    let met = habit.completedCount >= target
                    HStack(spacing: 2) {
                        if met {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        Text("\(habit.completedCount)/\(target)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(met ? theme.completedColor : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(met ? theme.completedColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                }
            }

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let state = habit.days[index]
                    let isToday = index == 6

                    VStack(spacing: 4) {
                        Circle()
                            .fill(screenshotColor(for: state, theme: theme))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)

                        Circle()
                            .fill(theme.indicatorColor)
                            .frame(width: 4, height: 4)
                            .opacity(isToday ? 1 : 0)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func localizedDayLabels() -> [String] {
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

- [ ] **Step 2: Add a raw preview (unframed) to verify layout**

```swift
#Preview("Raw - Habit List A", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotHabitList(data: treatmentA)
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Remove the temporary Frame test preview from Task 2, commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add hero habit list screenshot view"
```

---

### Task 4: Screenshot Screen 2 — Heatmap

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

- [ ] **Step 1: Add the ScreenshotHeatmap view**

```swift
// MARK: - Screen 2: Heatmap

struct ScreenshotHeatmap: View {
    let data: MockTreatment
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private let weekLabels = ["31/3", "7/4", "14/4", "21/4", "28/4", "5/5", "12/5", "19/5"]

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Heatmap")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 3) {
                // Week header row
                HStack(spacing: 3) {
                    Color.clear.frame(width: 100, height: 16)
                    ForEach(weekLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .frame(width: 30, height: 16)
                    }
                }

                // One row per habit
                ForEach(Array(data.habits.enumerated()), id: \.offset) { rowIndex, habit in
                    HStack(spacing: 3) {
                        Text(habit.name)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .trailing)
                            .lineLimit(1)

                        ForEach(Array(data.heatmapGrid[rowIndex].enumerated()), id: \.offset) { _, count in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(heatColor(count: count))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(count: level * 2))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(Color(.systemBackground))
    }

    private func heatColor(count: Int) -> Color {
        switch count {
        case 0: return .gray.opacity(0.15)
        case 1: return theme.completedColor.opacity(0.25)
        case 2: return theme.completedColor.opacity(0.4)
        case 3: return theme.completedColor.opacity(0.55)
        case 4: return theme.completedColor.opacity(0.7)
        case 5: return theme.completedColor.opacity(0.85)
        default: return theme.completedColor
        }
    }
}
```

- [ ] **Step 2: Add raw preview**

```swift
#Preview("Raw - Heatmap A", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotHeatmap(data: treatmentA)
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add heatmap screenshot view"
```

---

### Task 5: Screenshot Screen 3 — Widgets (Mock Home Screen)

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

- [ ] **Step 1: Add the ScreenshotWidgets view**

This is a mock home screen with two widget cards. The widgets are simplified recreations — not actual WidgetKit views.

```swift
// MARK: - Screen 3: Widgets (Mock Home Screen)

struct ScreenshotWidgets: View {
    let data: MockTreatment
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.15, green: 0.15, blue: 0.35),
                    Color(.sRGB, red: 0.10, green: 0.20, blue: 0.30),
                    Color(.sRGB, red: 0.08, green: 0.12, blue: 0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                mockStatusBar
                    .padding(.top, 12)

                Spacer().frame(height: 8)

                // Time
                Text("9:41")
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)

                Text("Monday, May 26")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer().frame(height: 32)

                // Widget: Habit Week
                mockWeekWidget
                    .padding(.horizontal, 20)

                Spacer().frame(height: 16)

                // Widget: Habits Today
                mockTodayWidget
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private var mockStatusBar: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 13))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
    }

    private var mockWeekWidget: some View {
        let habit = data.habits[0]
        return VStack(spacing: 8) {
            Text(habit.name)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text(dayLabels[index])
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(screenshotColor(for: habit.days[index], theme: theme))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if index == 6 {
                                    Circle()
                                        .strokeBorder(.primary.opacity(0.3), lineWidth: 1.5)
                                }
                            }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    private var mockTodayWidget: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.habits.prefix(4).enumerated()), id: \.element.id) { index, habit in
                if index > 0 {
                    Divider().padding(.leading, 48)
                }
                HStack(spacing: 12) {
                    Circle()
                        .fill(screenshotColor(for: habit.days[5], theme: theme))
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)

                        Text("\(habit.completedCount)/\(habit.target ?? 7) this week")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

}
```

- [ ] **Step 2: Add raw preview**

```swift
#Preview("Raw - Widgets A", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotWidgets(data: treatmentA)
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add mock home screen widgets screenshot view"
```

---

### Task 6: Screenshot Screen 4 — Stats

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

- [ ] **Step 1: Add the ScreenshotStats view**

```swift
// MARK: - Screen 4: Stats

struct ScreenshotStats: View {
    let data: MockTreatment

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                statCard(title: "Current Streak", value: "\(data.stats.currentStreak)", unit: "weeks", systemImage: "flame.fill", color: .orange)
                statCard(title: "Best Week", value: "\(data.stats.bestWeek)", unit: "completions", systemImage: "trophy.fill", color: .yellow)
                statCard(title: "Completion Rate", value: "\(data.stats.completionRate)%", unit: "overall", systemImage: "chart.pie.fill", color: .green)
                statCard(title: "Total Completions", value: "\(data.stats.totalCompletions)", unit: "days", systemImage: "checkmark.circle.fill", color: .blue)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func statCard(title: String, value: String, unit: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Add raw preview**

```swift
#Preview("Raw - Stats A", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotStats(data: treatmentA)
}
```

- [ ] **Step 3: Verify it compiles and commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add stats screenshot view"
```

---

### Task 7: Screenshot Screen 5 — Themes

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

- [ ] **Step 1: Add the ScreenshotThemes view**

```swift
// MARK: - Screen 5: Themes

struct ScreenshotThemes: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(AppTheme.allCases) { t in
                    themeCard(t)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func themeCard(_ t: AppTheme) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Mini habit circles preview
                HStack(spacing: 8) {
                    Circle().fill(t.completedColor).frame(width: 24, height: 24)
                    Circle().fill(t.completedColor).frame(width: 24, height: 24)
                    Circle().fill(t.failedColor).frame(width: 24, height: 24)
                    Circle().fill(t.completedColor).frame(width: 24, height: 24)
                    Circle().fill(t.notCompletedColor).frame(width: 24, height: 24)
                }

                // Streak badge preview
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("5")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))

            Text(t.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(t.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Add raw preview**

```swift
#Preview("Raw - Themes", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotThemes()
}
```

- [ ] **Step 3: Verify it compiles and commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add themes screenshot view"
```

---

### Task 8: Screenshot Screen 6 — Streaks + Goals Detail

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

- [ ] **Step 1: Add the ScreenshotStreaks view**

Shows 3 habit rows with extra vertical space and prominent badges. Picks the 3 habits with the best streaks from the dataset.

```swift
// MARK: - Screen 6: Streaks + Goals Detail

struct ScreenshotStreaks: View {
    let data: MockTreatment
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme.from(rawValue: selectedThemeRaw)
    }

    private var topHabits: [MockHabit] {
        Array(data.habits.sorted { $0.streak > $1.streak }.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            ForEach(topHabits) { habit in
                detailRow(habit)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                if habit.id != topHabits.last?.id {
                    Divider().padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func detailRow(_ habit: MockHabit) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(habit.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if habit.streak >= 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.subheadline)
                        Text("\(habit.streak) weeks")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                }

                if let target = habit.target {
                    let met = habit.completedCount >= target
                    HStack(spacing: 4) {
                        if met {
                            Image(systemName: "checkmark")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        Text("\(habit.completedCount)/\(target)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(met ? theme.completedColor : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(met ? theme.completedColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(screenshotColor(for: habit.days[index], theme: theme))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if index == 6 {
                                    Circle()
                                        .strokeBorder(theme.indicatorColor, lineWidth: 2.5)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Add raw preview**

```swift
#Preview("Raw - Streaks A", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotStreaks(data: treatmentA)
}
```

- [ ] **Step 3: Verify it compiles and commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add streaks and goals detail screenshot view"
```

---

### Task 9: Treatment Configurations and Framed Previews

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

Wire up the three treatment configurations and generate all 18 framed previews.

- [ ] **Step 1: Add treatment configuration type and the three treatments**

```swift
// MARK: - Treatment Configuration

struct ScreenshotSlot {
    let headline: String
    let subtitle: String?
    let screen: ScreenType
}

enum ScreenType {
    case habitList, heatmap, widgets, stats, themes, streaks
}

struct TreatmentConfig {
    let style: FrameStyle
    let data: MockTreatment
    let slots: [ScreenshotSlot]
}

let configA = TreatmentConfig(
    style: .dark,
    data: treatmentA,
    slots: [
        ScreenshotSlot(headline: "Build habits that stick", subtitle: nil, screen: .habitList),
        ScreenshotSlot(headline: "See your progress grow", subtitle: nil, screen: .heatmap),
        ScreenshotSlot(headline: "Your week at a glance", subtitle: "Beautiful home screen widgets", screen: .widgets),
        ScreenshotSlot(headline: "Every day counts", subtitle: nil, screen: .stats),
        ScreenshotSlot(headline: "Make it yours", subtitle: "6 themes included", screen: .themes),
        ScreenshotSlot(headline: "Stay on fire", subtitle: "Streaks and weekly goals", screen: .streaks),
    ]
)

let configB = TreatmentConfig(
    style: .light,
    data: treatmentB,
    slots: [
        ScreenshotSlot(headline: "See your streak grow", subtitle: "Weeks of consistency, visualized", screen: .heatmap),
        ScreenshotSlot(headline: "Simple. Satisfying. Effective.", subtitle: nil, screen: .habitList),
        ScreenshotSlot(headline: "Your progress in numbers", subtitle: nil, screen: .stats),
        ScreenshotSlot(headline: "Always on your home screen", subtitle: nil, screen: .widgets),
        ScreenshotSlot(headline: "Set goals, build streaks", subtitle: nil, screen: .streaks),
        ScreenshotSlot(headline: "Make it yours", subtitle: "6 themes included", screen: .themes),
    ]
)

let configC = TreatmentConfig(
    style: .gradient,
    data: treatmentC,
    slots: [
        ScreenshotSlot(headline: "Track habits. That's it.", subtitle: "Right from your home screen", screen: .widgets),
        ScreenshotSlot(headline: "Tap to complete, swipe to explore", subtitle: nil, screen: .habitList),
        ScreenshotSlot(headline: "Watch your consistency build", subtitle: nil, screen: .heatmap),
        ScreenshotSlot(headline: "Stay on fire", subtitle: "Automatic streak tracking", screen: .streaks),
        ScreenshotSlot(headline: "Every day counts", subtitle: nil, screen: .stats),
        ScreenshotSlot(headline: "Make it yours", subtitle: "6 themes included", screen: .themes),
    ]
)
```

- [ ] **Step 2: Add a helper view that resolves ScreenType to the actual view**

```swift
// MARK: - Screen Resolver

struct ScreenshotSlotView: View {
    let slot: ScreenshotSlot
    let style: FrameStyle
    let data: MockTreatment

    var body: some View {
        ScreenshotFrame(headline: slot.headline, subtitle: slot.subtitle, style: style) {
            switch slot.screen {
            case .habitList: ScreenshotHabitList(data: data)
            case .heatmap: ScreenshotHeatmap(data: data)
            case .widgets: ScreenshotWidgets(data: data)
            case .stats: ScreenshotStats(data: data)
            case .themes: ScreenshotThemes()
            case .streaks: ScreenshotStreaks(data: data)
            }
        }
    }
}
```

- [ ] **Step 3: Add all 18 framed previews**

```swift
// MARK: - Treatment A Previews (Dark)

#Preview("A1 - Hero (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[0], style: configA.style, data: configA.data)
}
#Preview("A2 - Heatmap (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[1], style: configA.style, data: configA.data)
}
#Preview("A3 - Widgets (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[2], style: configA.style, data: configA.data)
}
#Preview("A4 - Stats (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[3], style: configA.style, data: configA.data)
}
#Preview("A5 - Themes (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[4], style: configA.style, data: configA.data)
}
#Preview("A6 - Streaks (Dark)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configA.slots[5], style: configA.style, data: configA.data)
}

// MARK: - Treatment B Previews (Light)

#Preview("B1 - Heatmap (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[0], style: configB.style, data: configB.data)
}
#Preview("B2 - Hero (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[1], style: configB.style, data: configB.data)
}
#Preview("B3 - Stats (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[2], style: configB.style, data: configB.data)
}
#Preview("B4 - Widgets (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[3], style: configB.style, data: configB.data)
}
#Preview("B5 - Streaks (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[4], style: configB.style, data: configB.data)
}
#Preview("B6 - Themes (Light)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configB.slots[5], style: configB.style, data: configB.data)
}

// MARK: - Treatment C Previews (Gradient)

#Preview("C1 - Widgets (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[0], style: configC.style, data: configC.data)
}
#Preview("C2 - Hero (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[1], style: configC.style, data: configC.data)
}
#Preview("C3 - Heatmap (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[2], style: configC.style, data: configC.data)
}
#Preview("C4 - Streaks (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[3], style: configC.style, data: configC.data)
}
#Preview("C5 - Stats (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[4], style: configC.style, data: configC.data)
}
#Preview("C6 - Themes (Gradient)", traits: .fixedLayout(width: 430, height: 932)) {
    ScreenshotSlotView(slot: configC.slots[5], style: configC.style, data: configC.data)
}
```

- [ ] **Step 4: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "feat: add treatment configs and all 18 framed previews"
```

---

### Task 10: Screenshot Gallery View and Debug Menu Entry

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`
- Modify: `SimpleHabitTracker/Views/SettingsView.swift`

- [ ] **Step 1: Add ScreenshotGalleryView to ScreenshotPreviews.swift**

```swift
// MARK: - Screenshot Gallery (Debug)

struct ScreenshotGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTreatment: String = "A"
    @State private var showControls = true

    private var config: TreatmentConfig {
        switch selectedTreatment {
        case "B": return configB
        case "C": return configC
        default: return configA
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                ForEach(Array(config.slots.enumerated()), id: \.offset) { index, slot in
                    ScreenshotSlotView(slot: slot, style: config.style, data: config.data)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: showControls ? .automatic : .never))

            if showControls {
                HStack {
                    Picker("Treatment", selection: $selectedTreatment) {
                        Text("A — Dark").tag("A")
                        Text("B — Light").tag("B")
                        Text("C — Gradient").tag("C")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 8)
            }
        }
        .onTapGesture { withAnimation { showControls.toggle() } }
        .statusBarHidden(!showControls)
    }
}
```

- [ ] **Step 2: Add gallery button to SettingsView debug section**

In `SimpleHabitTracker/Views/SettingsView.swift`, add a `@State private var showScreenshotGallery = false` property inside the `#if DEBUG` block (alongside the existing debug properties, or at the view level guarded by `#if DEBUG`), and add a button + sheet to the debug section.

Since the `showScreenshotGallery` state needs to live at the view scope (not inside the computed property), add it as a regular `@State` property on `SettingsView`. The `ScreenshotGalleryView` type is only available in DEBUG, so the sheet must also be inside `#if DEBUG`.

Add this property to `SettingsView`:
```swift
#if DEBUG
@State private var showScreenshotGallery = false
#endif
```

Add this button inside the existing `debugSection` computed property, before the "Clear All Data" button:
```swift
Button {
    showScreenshotGallery = true
} label: {
    Label("Screenshot Gallery", systemImage: "camera")
}
```

Add a `.sheet` modifier inside the `#if DEBUG` block. The cleanest place is on the `debugSection`'s `Section` or as a modifier on the `Form`. Add it as a modifier on the `Form` in the `body`, inside a `#if DEBUG` block:

```swift
#if DEBUG
.sheet(isPresented: $showScreenshotGallery) {
    ScreenshotGalleryView()
}
#endif
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild build -project SimpleHabitTracker.xcodeproj -scheme SimpleHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift SimpleHabitTracker/Views/SettingsView.swift
git commit -m "feat: add screenshot gallery debug view and settings entry"
```

---

### Task 11: Visual Polish Pass

**Files:**
- Modify: `SimpleHabitTracker/Views/ScreenshotPreviews.swift`

Open Xcode previews and visually inspect all 18 screenshots. Fix any layout issues.

- [ ] **Step 1: Open Xcode and check all previews render**

Run: `open SimpleHabitTracker.xcodeproj`

Navigate to `ScreenshotPreviews.swift` and check the Preview canvas. Verify:
- All 18 framed previews render without errors
- All 6 raw previews render without errors
- Frame headlines are legible and centered
- Content cards are properly clipped and shadowed
- No text truncation on habit names or badges

- [ ] **Step 2: Fix any issues found**

Common things to adjust:
- Padding values if content overflows the card
- Font sizes if text is too small/large in the frame
- Background colors if they don't contrast well with the frame
- Heatmap cell sizing to fit within the card width

- [ ] **Step 3: Test the gallery in the simulator**

Run the app in the simulator, go to Settings > Debug > Screenshot Gallery. Verify:
- Segmented control switches between treatments
- Swiping between screenshots works
- Tap to hide/show controls works
- Dismiss button works

- [ ] **Step 4: Commit any polish fixes**

```bash
git add SimpleHabitTracker/Views/ScreenshotPreviews.swift
git commit -m "fix: polish screenshot preview layouts"
```
