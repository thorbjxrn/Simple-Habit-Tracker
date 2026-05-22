# Simple Habit Tracker — WidgetKit Widgets

## Overview

Add four home screen widgets to Simple Habit Tracker using WidgetKit with App Intents for interactive completion toggling. Free users get a single-habit widget; premium users unlock full-week, multi-habit, and heatmap widgets.

## Widget Variants

### 1. Single Habit Today (Small) — Free

- Displays one user-selected habit name and today's completion dot
- Tap the dot to cycle state: notCompleted → completed → failed → notCompleted
- Tap anywhere else to deep link into the app
- Configured via `AppIntentConfiguration` with a single habit picker

### 2. Single Habit Week (Medium) — Premium

- Displays one user-selected habit name and 7 day dots for the current week
- Day labels (M T W T F S S) above or below dots
- Today's dot is tappable to toggle state; past/future dots are display-only
- Tap outside dots to deep link into the app

### 3. Multi-Habit Today (Medium + Large) — Premium

- Displays a user-selected list of habits, each with their name and today's dot
- Medium: up to ~4 habits; Large: up to ~8 habits
- Each dot is independently tappable to toggle that habit's state
- Tap anywhere else to deep link into the app
- Configured via multi-select habit picker in intent configuration

### 4. Heatmap (Large) — Premium

- Displays the same completion heatmap grid as the in-app `HeatmapPanel`
- Read-only (no interactive toggles) — tap anywhere to deep link into the app
- Shows recent weeks of aggregate completion data across all habits
- Color intensity maps to daily completion percentage

## Theming

- Widgets read `selectedTheme` from shared `UserDefaults` (via App Group)
- Dot colors use the theme's `completedColor`, `failedColor`, `notCompletedColor`
- Heatmap uses theme's `completedColor` at varying opacities
- Widget background: system default (no custom tint), so widgets feel native while dots carry the theme personality
- Dynamic theme resolves based on current time, same as in-app

## Interaction Model

- **Dot tap**: Toggles completion state via an `AppIntent` that writes directly to the shared SwiftData store. After toggling, the intent triggers a timeline reload so the widget updates immediately.
- **Background tap**: Opens the app via a `widgetURL` deep link. No specific destination needed — just opens to the main habit list.
- Haptics are not available in widgets (system limitation).

## Data Architecture

### App Group

- Register an App Group (e.g., `group.com.thorbjxrn.simplehabittracker`) in both the main app target and the widget extension target
- Move the SwiftData `ModelContainer` to use the App Group's shared container directory so both processes read/write the same store

### Shared Code

Code shared between the app and widget extension (extracted into a shared target or just added to both targets):

- `Habit` model
- `WeekRecord` model
- `HabitState` enum
- `AppTheme` enum (for color resolution)
- A lightweight read/write helper that can fetch habits, get today's week record, and toggle a day's state — no dependency on `HabitViewModel`'s full surface

### Timeline Provider

- `TimelineProvider` returns a timeline entry for the current state, with a refresh policy of `.after` midnight (so day labels and "today" indicator update at day boundaries)
- Additional reloads triggered by: app returning to foreground (`WidgetCenter.shared.reloadAllTimelines()`), and after each `AppIntent` toggle

## Premium Gating

- The widget extension reads `isPremiumCached` from shared `UserDefaults` (already written by `PurchaseManager.updatePremiumStatus`)
- Premium-only widgets (week, multi-habit, heatmap) check this flag at render time
- If a premium widget is on the home screen and premium lapses: show a graceful "Upgrade to Premium" placeholder instead of habit data
- The free single-habit widget always works regardless of premium status

## App Intents

### ToggleHabitIntent

- Parameters: `habitID: UUID`, `dayIndex: Int`
- Opens the shared SwiftData store, finds the habit, gets or creates the current week record, cycles the day state
- Returns `.result()` and triggers `WidgetCenter.shared.reloadAllTimelines()`

### Habit Entity / Query

- `HabitEntity` conforming to `AppEntity` for the intent configuration picker
- `HabitQuery` conforming to `EntityQuery` that fetches from the shared SwiftData store
- Used by all widget configurations to let users pick which habit(s) to display

## Widget Extension Structure

Single widget extension target containing a `WidgetBundle` with all four widgets. Each widget has its own `Widget` struct, `TimelineProvider`, and `EntryView`.

## Minimum Deployment Target

iOS 17.0 — required for interactive widget intents (`Button` and `Toggle` in widget views) and `AppIntentConfiguration`.

## Out of Scope

- Lock Screen widgets (can be added later as a follow-up)
- Watch complications
- Streak display in widgets (keep it simple for v1)
- Widget-specific onboarding or tutorial
