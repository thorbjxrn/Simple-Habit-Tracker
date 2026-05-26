# App Store Screenshot Gallery

**Date:** 2026-05-26
**Scope:** App Store screenshot preview system with three A/B/C test treatments

## Goals

1. Create polished App Store screenshots that convert impressions to installs
2. Support three distinct treatments for App Store Connect product page optimization
3. Keep everything `#if DEBUG` — zero production impact
4. Follow the proven pattern from the Overdubber's `ScreenshotPreviews.swift`

## Architecture

One file: `ScreenshotPreviews.swift`, wrapped in `#if DEBUG`. Contains:

- Mock data structs (habits, week patterns, heatmap grids, stats)
- Three mock datasets tailored to each treatment's persona
- Six screenshot content views (self-contained, no SwiftData/ViewModel dependencies)
- `ScreenshotFrame` wrapper parameterized by `FrameStyle` enum
- `ScreenshotGalleryView` for in-app debug preview (swipeable)
- Xcode `#Preview` providers at exact device dimensions (430x932 for 6.7")

---

## 1. Frame Styles

Three visual treatments, controlled by a `FrameStyle` enum:

### `.dark` (Treatment A)

- Background: `#121219` (near-black)
- Headline: white, bold, rounded sans-serif (~32pt)
- Subtitle: white at 70% opacity
- Content card: rounded corners (20pt), white border at 8% opacity, drop shadow

### `.light` (Treatment B)

- Background: `#F5F5F7` (Apple product-page off-white)
- Headline: dark charcoal (`#1D1D1F`), bold
- Subtitle: medium gray (`#6E6E73`)
- Content card: rounded corners, light shadow, no border

### `.gradient` (Treatment C)

- Background: diagonal gradient from green (`#34C759` — iOS system green) to teal (`#30B0C7`)
- Headline: white, bold
- Subtitle: white at 80% opacity
- Content card: rounded corners, frosted glass border effect (white at 15% opacity)

All three share the same `ScreenshotFrame` API:
```swift
ScreenshotFrame(headline: "...", subtitle: "...", style: .dark) {
    ScreenshotHeroHabitList(data: treatmentA)
}
```

---

## 2. Screenshot Screens (6 total)

Each screen is a standalone SwiftUI view that takes mock data as input.

### Screen 1: Hero Habit List

Recreates the main `HabitTrackerView` portrait layout with static data:
- "This Week" header with chevron navigation arrows
- Day-of-week labels (M T W T F S S)
- 5 habit rows with name, colored circles (Mon-Sat filled, Sun empty), streak badges, weekly goal badges
- No banner ad, no tip view

### Screen 2: Heatmap

Recreates the `HeatmapPanel` with static grid data:
- Title: "Heatmap"
- Habit names on the left, week date labels across the top
- Colored grid cells (gray -> themed green at increasing opacity)
- Legend row (Less -> More)
- 8 weeks of data, 5 habits

### Screen 3: Widgets (Mock Home Screen)

A composed mock iPhone home screen:
- Soft gradient or blurred wallpaper background
- Mock status bar (time, signal, Wi-Fi, battery)
- Two medium-size widget cards stacked vertically:
  - "Habit Week" — habit name + 7 day circles (like `SingleHabitWeekView`)
  - "Habits Today" — multi-habit list with colored dots and weekly counts (like `MultiHabitTodayView`)
- Widget cards use standard iOS rounded corners (~20pt), light shadow, `.fill.tertiary`-style background

Note: These are simplified recreations of the widget views, not actual WidgetKit renders. They live in the main app target and are purely visual.

### Screen 4: Stats

Recreates the `StatsPanel` layout with static numbers:
- Title: "Statistics"
- 2x2 grid of stat cards, each with: icon, value, title, unit
- Cards have rounded corners, subtle shadow, colored icon and border accent

### Screen 5: Themes

Grid showing all 6 themes with mini habit-row previews:
- 2x3 grid (or 3x2 depending on what fits better)
- Each card shows: a row of 3 colored circles (completed/failed/notCompleted) in that theme's colors, theme name below
- Similar to the Overdubber's `themeCard` pattern but with habit circles instead of waveforms

### Screen 6: Streaks + Goals Detail

Close-up of 2-3 habit rows emphasizing the streak and goal system:
- Larger habit rows than the hero shot (more vertical space per row)
- Prominent flame badges with multi-week streaks
- Weekly goal badges showing met/unmet states
- Possibly a subtle callout annotation pointing to the streak badge

---

## 3. Treatments (A/B/C)

Each treatment pairs a frame style, screenshot order, headline copy, and mock dataset.

### Treatment A — "The Functional Pitch" (Dark frame)

**Story:** "Here's exactly what this app does, and it does it well."

| # | Screen | Headline | Subtitle |
|---|---|---|---|
| 1 | Habit list | "Build habits that stick" | — |
| 2 | Heatmap | "See your progress grow" | — |
| 3 | Widgets | "Your week at a glance" | "Beautiful home screen widgets" |
| 4 | Stats | "Every day counts" | — |
| 5 | Themes | "Make it yours" | "6 themes included" |
| 6 | Streaks + Goals | "Stay on fire" | "Streaks and weekly goals" |

**Mock Data — "The Everyday User"**

Relatable habits, honest mix of wins and misses.

| Habit | Mon | Tue | Wed | Thu | Fri | Sat | Sun | Streak | Goal |
|---|---|---|---|---|---|---|---|---|---|
| Morning Run | done | done | done | fail | done | done | — | 3 wks | 5/5 met |
| Read 10 Pages | done | done | done | done | done | done | — | 6 wks | 6/6 met |
| Meditate | done | fail | done | done | fail | done | — | 1 wk | 4/5 not met |
| No Phone in Bed | done | done | fail | done | done | done | — | 2 wks | — |
| Practice Guitar | fail | done | fail | done | fail | done | — | 0 | 3/4 not met |

Stats: 6-week streak, best week 32, 78% rate, 147 total.

Heatmap: 8 weeks, moderate density, trending upward.

### Treatment B — "The Aspirational Pitch" (Light frame)

**Story:** "Look how satisfying consistency feels."

| # | Screen | Headline | Subtitle |
|---|---|---|---|
| 1 | Heatmap | "See your streak grow" | "Weeks of consistency, visualized" |
| 2 | Habit list | "Simple. Satisfying. Effective." | — |
| 3 | Stats | "Your progress in numbers" | — |
| 4 | Widgets | "Always on your home screen" | — |
| 5 | Streaks + Goals | "Set goals, build streaks" | — |
| 6 | Themes | "Make it yours" | "6 themes included" |

**Mock Data — "The Streak Machine"**

Aspirational habits, impressive streaks.

| Habit | Mon | Tue | Wed | Thu | Fri | Sat | Sun | Streak | Goal |
|---|---|---|---|---|---|---|---|---|---|
| Gym | done | done | done | done | done | done | — | 8 wks | 6/6 met |
| Read 30 Minutes | done | done | done | done | done | done | — | 12 wks | 6/6 met |
| Journal | done | done | done | done | done | fail | — | 5 wks | 5/6 not met |
| Cold Shower | done | done | done | done | done | done | — | 4 wks | 6/6 met |
| Cook at Home | done | done | fail | done | done | done | — | 3 wks | 5/5 met |

Stats: 12-week streak, best week 34, 91% rate, 312 total.

Heatmap: 8 weeks, dense green, almost fully filled.

### Treatment C — "The Utility Pitch" (Gradient frame)

**Story:** "This integrates into your daily life effortlessly."

| # | Screen | Headline | Subtitle |
|---|---|---|---|
| 1 | Widgets | "Track habits. That's it." | "Right from your home screen" |
| 2 | Habit list | "Tap to complete, swipe to explore" | — |
| 3 | Heatmap | "Watch your consistency build" | — |
| 4 | Streaks + Goals | "Stay on fire" | "Automatic streak tracking" |
| 5 | Stats | "Every day counts" | — |
| 6 | Themes | "Make it yours" | "6 themes included" |

**Mock Data — "The Quick Check"**

Low-friction daily habits. Simple, fast, fits a busy life.

| Habit | Mon | Tue | Wed | Thu | Fri | Sat | Sun | Streak | Goal |
|---|---|---|---|---|---|---|---|---|---|
| Drink Water | done | done | done | done | done | done | — | 4 wks | — |
| Take Vitamins | done | done | done | fail | done | done | — | 2 wks | — |
| Stretch | done | fail | done | done | done | done | — | 1 wk | 4/5 met |
| Walk 10k Steps | done | done | done | done | fail | done | — | 3 wks | 5/5 met |
| No Snooze | fail | done | done | done | done | done | — | 2 wks | — |

Stats: 4-week streak, best week 24, 82% rate, 89 total.

Heatmap: 8 weeks, moderate density, steady.

---

## 4. Debug Integration

### Screenshot Gallery View

A swipeable `TabView` accessible from the debug section in `SettingsView`:
- Page-style tab view showing all framed screenshots
- Toggle or segmented control to switch between treatments (A/B/C)
- Tap to hide/show controls (like the Overdubber)
- Dismiss button

### Settings Debug Menu Entry

Add a "Screenshot Gallery" button to the existing `#if DEBUG` section in `SettingsView`.

---

## 5. Xcode Previews

Each of the 18 combinations (6 screens x 3 treatments) gets a `#Preview` at exact device dimensions:
- iPhone 15 Pro Max: `430 x 932` (6.7" — required for App Store)

Preview naming convention: `"A1 - Hero (Dark)"`, `"B1 - Heatmap (Light)"`, `"C1 - Widgets (Gradient)"`, etc.

Raw (unframed) previews for each screen are also included for iteration on the content without the frame.

---

## 6. Out of Scope

- iPad screenshots (can be added later)
- Fastlane/snapshot automation
- Localized screenshot text
- Device frame mockups (bezels around the screenshots — App Store Connect handles this)
- Actual WidgetKit rendering in screenshots
