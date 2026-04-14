# Simple Habit Tracker

A simple, focused iOS habit tracker. Track your habits one week at a time.

## Philosophy

- Simple first. No login, no subscription, no social.
- Free version feels complete, not crippled.
- Premium is a genuine bonus, not a ransom.

## Features

### Free
- Create, rename, and delete habits (up to 5)
- 3-state day toggle: skip, done, missed
- Week-by-week navigation (swipe or chevrons)
- 2 weeks of history
- Today indicator (ring or dot style, configurable)
- Landscape dashboard with monthly calendar, trends, and stats
- Haptic feedback
- Onboarding flow
- 5 color themes (Default, Ocean, Sunset, Lavender, Monochrome)
- Fun rotating placeholder suggestions when adding habits

### Premium (one-time purchase)
- Unlimited habits
- Full history (scroll back indefinitely)
- iCloud sync across devices
- Ad removal
- Weekly goals per habit with progress badges
- Extended calendar history (24 months)

## Tech Stack

- SwiftUI + SwiftData (iOS 17.0+)
- StoreKit 2 for in-app purchases
- Google AdMob for ads
- Swift Charts for trend graphs
- CloudKit for iCloud sync
- Zero first-party dependencies beyond Apple frameworks + AdMob

## Architecture

MVVM with `@Observable` ViewModel and SwiftData `@Model` entities.

- `Habit` — tracks name, sort order, premium fields (theme, weekly goal)
- `WeekRecord` — stores 7-day completion state per habit per week
- `PurchaseManager` — StoreKit 2 integration
- `AdManager` — AdMob with grace period (no ads for first 5 opens)
- `ThemeManager` — 5 color themes
- `MigrationManager` — one-time UserDefaults to SwiftData migration

## Project Structure

```
SimpleHabitTracker/
  SimpleHabitTrackerApp.swift
  HabitTrackerView.swift
  HabitViewModel.swift
  PurchaseManager.swift
  AdManager.swift
  Models/
    HabitModel.swift
    HabitState.swift
    WeekRecord.swift
  Views/
    HabitRowView.swift
    WeekNavigationView.swift
    SettingsView.swift
    PaywallView.swift
    OnboardingView.swift
    BannerAdView.swift
    DashboardView.swift
    DashboardPanels/
      MonthlyCalendarPanel.swift
      TrendGraphPanel.swift
      StatsPanel.swift
  Utilities/
    MigrationManager.swift
    ThemeManager.swift
```

## Setup

1. Open `SimpleHabitTracker.xcodeproj` in Xcode
2. Add GoogleMobileAds SPM package: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
3. Add iCloud capability with container `iCloud.thorbjxrn.SimpleHabitTracker`
4. Add Push Notifications capability
5. Build and run

## Roadmap

- [ ] App icon (1024x1024 PNG)
- [ ] App Store screenshots and metadata
- [ ] Privacy policy page
- [ ] Unit and UI tests
- [ ] Apple Health integration
- [ ] Widgets
- [ ] Notifications / reminders
- [ ] Apple Watch companion
