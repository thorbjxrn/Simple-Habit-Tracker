# Simple Habit Tracker v1.0 - Design Spec

## Context

Simple Habit Tracker is a personal iOS habit tracking app built in SwiftUI. The existing MVP supports creating/deleting/renaming habits, a 7-day week view with 3-state toggles (not done / completed / failed), streak visualization, and UserDefaults persistence with automatic weekly reset. The codebase is ~4 source files, zero dependencies, MVVM architecture.

**Goal:** Finish, publish to the App Store, and monetize with a minimalist philosophy - no login, no subscription, no social features. The app should feel simple, fast, and honest.

## Design Philosophy

- Simple first. Every feature must earn its place.
- Free version feels complete, not crippled.
- Premium feels like a genuine bonus, not a ransom.
- Zero friction: no accounts, no sign-up, no social.
- Performance is non-negotiable: smooth animations, no jank.

---

## 1. Data Model & Persistence

### Current State
- `Habit` struct with `id`, `name`, `completedDays: [HabitState]` (7-element array)
- `HabitState` enum: `.notCompleted`, `.completed`, `.failed`
- Stored in UserDefaults via JSONEncoder/JSONDecoder
- Week reset via Calendar week-of-year comparison

### v1.0 Changes

**Migrate from UserDefaults to SwiftData + CloudKit.**

**Habit model:**
- `id: UUID`
- `name: String`
- `createdDate: Date`
- `sortOrder: Int`
- `colorTheme: String?` (premium - nil uses default)
- `targetDaysPerWeek: Int?` (premium - nil means no weekly goal)

**WeekRecord model (new):**
- `id: UUID`
- `habit: Habit` (SwiftData `@Relationship` back to Habit)
- `weekStartDate: Date`
- `completedDays: [HabitState]` (7-element array, same enum)

Habit has a `@Relationship(deleteRule: .cascade)` to its WeekRecords - deleting a habit deletes all its history.

Separating weekly data into `WeekRecord` gives history naturally - each week is a new record instead of overwriting.

**Premium state:**
- `PurchaseManager` using StoreKit 2
- `isPremium: Bool` derived from StoreKit transaction state
- Persisted locally + verified via App Store receipt

**Migration:**
- One-time migration on first launch: read existing UserDefaults data, create SwiftData `Habit` + `WeekRecord` entries, clear UserDefaults keys.

**iCloud sync (premium):**
- SwiftData + CloudKit container enables sync with minimal code
- Toggle in settings to enable/disable
- Sync is automatic and invisible to the user

---

## 2. Free vs Premium Feature Split

### Free Tier
- Create, delete, rename habits
- 3-state day toggle (not done / completed / failed)
- Streak lines between consecutive completed days
- Current week view
- Up to 5 habits
- 2 weeks of history (current + last week)
- Haptic feedback
- Light/dark mode (system default)
- Landscape dashboard (all panels, but history content limited to 2 weeks)
- Banner ad on main screen (portrait)
- Interstitial ad every 3rd app open (no ads on first session)
- Interstitial ad when navigating to past weeks

### Premium (one-time IAP, ~$3.99)
- Remove all ads (banner + interstitials)
- Unlimited habits
- Full history (scroll back indefinitely)
- iCloud sync across devices
- Weekly completion stats
- Weekly goals per habit (target X of 7 days, success = completed days >= target)
- 3-4 color themes (accent colors for circles/streaks)

### Paywall Behavior
- Soft paywall sheet triggered when:
  - Adding a 6th habit
  - Scrolling past 2 weeks of history
  - Tapping theme or iCloud options in settings
- Always dismissible, never blocks core functionality
- No ads shown during first session (let user fall in love first)

---

## 3. Ad Strategy

**Provider:** Google AdMob (industry standard, best revenue)

**Placements:**
1. **Banner ad** - bottom of main screen in portrait mode. Small, non-intrusive.
2. **Interstitial on app open** - every 3rd app launch. Full-screen, natural breakpoint.
3. **Interstitial on history navigation** - when swiping to view past weeks. Natural pause point.

**Rules:**
- No ads during the user's first session (grace period)
- All ads removed with premium IAP
- ATT (App Tracking Transparency) prompt on second session
- `PrivacyInfo.xcprivacy` manifest declaring AdMob data collection

**Dependency:** GoogleMobileAds Swift Package

---

## 4. UI & Navigation

### Screen Structure

**1. Main Screen (Habit List) - Portrait**
- NavigationStack with habit list
- Week view with day circles per habit (as today, polished)
- Swipeable left/right to navigate between weeks
- Week indicator at top: "This Week", "Last Week", or date range (e.g., "Mar 24-30")
- "+" button to add habits
- Gear icon in nav bar for settings
- Banner ad at bottom (free tier)
- Current day indicator (yellow dot, as today)
- Streak lines between consecutive completed days (as today)

**2. Landscape Dashboard (all users)**
A rich, dedicated analytics experience that uses the horizontal space. Multiple swipeable or auto-rotating panels:
- **Monthly calendar view** - Full month grid showing completed/failed/missed per habit
- **Graphs** - Completion trends over time (weekly completion % over recent months)
- **Stats** - Streaks, best week, completion rates, totals

Performance and smooth animations are critical. Detailed panel layouts will be refined during implementation. Free tier users see data limited to their 2-week history window; premium users see full history.

**3. Settings Screen**
Accessible via gear icon in nav bar:
- "Upgrade to Premium" (if free tier)
- "Restore Purchases" (required by Apple)
- Theme selector (premium)
- iCloud sync toggle (premium)
- About / privacy policy link

**4. Onboarding (first launch only)**
2 screens maximum:
- Screen 1: "Track your habits, one week at a time" + brief visual
- Screen 2: Quick tutorial - tap to toggle states, swipe to navigate weeks

**5. Paywall Sheet**
Modal sheet showing:
- What premium includes
- Price
- Purchase button
- Dismiss button (always available)

### No Tab Bar
Single main screen with settings via nav bar. Landscape dashboard activates on rotation. Keeps the "open, toggle, done" simplicity.

---

## 5. Technical Architecture

### Frameworks & Dependencies
- **SwiftUI** - UI layer
- **SwiftData** - persistence + CloudKit sync
- **StoreKit 2** - in-app purchases
- **GoogleMobileAds** - ad serving (only external dependency)

### Key Components
- `SimpleHabitTrackerApp.swift` - App entry point, SwiftData container setup
- `HabitModel.swift` - Habit + WeekRecord SwiftData models
- `HabitViewModel.swift` - State management, CRUD operations, week logic
- `PurchaseManager.swift` - StoreKit 2 purchase handling, premium state
- `AdManager.swift` - AdMob integration, ad frequency logic, grace period tracking
- `HabitTrackerView.swift` - Main portrait view
- `DashboardView.swift` - Landscape dashboard with rotating panels
- `SettingsView.swift` - Settings screen
- `OnboardingView.swift` - First-launch onboarding
- `PaywallView.swift` - Premium upgrade sheet
- `MigrationManager.swift` - One-time UserDefaults to SwiftData migration

### Minimum Deployment Target
- iOS 17.0 (lowered from 17.5 to capture more users; SwiftData still supported)

---

## 6. App Store Requirements

### Must-Have Before Submission
- **App icon** - 1024x1024 PNG, clean and minimal (circle + checkmark concept)
- **Screenshots** - 3-5 showing main flow (iPhone required, iPad recommended)
- **Privacy policy** - Hosted URL (GitHub Pages or similar). Required due to AdMob data collection.
- **App Store metadata:**
  - Name: "Simple Habit Tracker"
  - Subtitle: "Track daily habits, one week at a time"
  - Category: Health & Fitness (primary), Productivity (secondary)
  - Keywords: habit tracker, daily habits, weekly habits, streak, routine, simple
  - Description: Short, honest, emphasizing simplicity
- **PrivacyInfo.xcprivacy** - Privacy manifest (required for iOS 17+, especially with AdMob)
- **Bundle ID:** `thorbjxrn.SimpleHabitTracker` (already configured)
- **App Store Connect** - IAP product configured, pricing set

---

## 7. Testing Strategy

### Unit Tests
- Habit CRUD operations (add, delete, rename)
- WeekRecord creation and state toggling
- Week reset logic (calendar boundary detection)
- History limiting (free tier: 2 weeks, premium: unlimited)
- Habit count limiting (free: 5, premium: unlimited)
- Weekly goal calculation (completed days >= target)
- UserDefaults to SwiftData migration
- Premium state gating

### UI Tests
- Add/delete/rename habit flow
- Day state toggling (3-state cycle)
- Week navigation (swipe between weeks)
- Paywall trigger points (6th habit, history limit)
- Settings screen navigation
- Onboarding flow (first launch)

### Manual QA
- Landscape dashboard panel navigation and performance
- Ad display at correct intervals
- IAP purchase and restore flow
- iCloud sync between devices
- Migration from existing UserDefaults data
- Dark mode appearance
- Various device sizes (iPhone SE through Pro Max, iPad)

---

## 8. Out of Scope (v1.0)

These features are explicitly deferred to future versions:
- Apple Health integration
- Partial day completion (0-100% slider)
- Badge/reward animations for completing weekly goals
- Social features / sharing
- Notifications / reminders
- Widgets
- Apple Watch companion
- Localization / translations
