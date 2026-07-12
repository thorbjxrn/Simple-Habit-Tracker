# Simple Habits Backlog

## Release status

- 1.2.2 SUBMITTED 2026-07-12 (WAITING_FOR_REVIEW, auto-release after approval). Contains: 4 widget fixes (dropped toggles, dead deep links, stale-on-foreground via container rebuild, sibling reload budget), CloudKit launch-crash fix (optional relationships), iCloud sync automatic with Premium (no toggle), no-ATT non-personalized ads, rotation via window-shape, VersionedSchema V1 baseline, safe app-group URL, rewritten App Store description. Manual: App Privacy questionnaire updated to Device ID + Advertising Data, not used for tracking.

## Tech Debt / Hardening (from 2026-07 health check, full reports in scratch/)

- [x] ~~Migration decode failure silently deletes legacy data~~ — retry instead of marking complete
- [x] ~~CloudKit-incompatible @Model schema~~ — inline defaults on Habit/WeekRecord (fixes iCloud Sync crash loop)
- [x] ~~ATT missing despite AdMob + privacy policy promising it~~ — ATT request gates MobileAds start
- [x] ~~VoiceOver can't reach day-toggle circles~~ — label/value/action on HabitRowView circles
- [x] ~~ITSAppUsesNonExemptEncryption missing~~
- [x] ~~Reconcile ads privacy story~~ — decision 2026-07-11: NO ATT prompt, non-personalized ads only (npa=1 on every request via AdManager.nonPersonalizedRequest). ATT code + NSUserTrackingUsageDescription removed; manifest: tracking=false, DeviceID/AdvertisingData declared non-tracking; widget extension has its own manifest (CA92.1). REMAINING MANUAL STEP: ASC questionnaire — Device ID + Advertising Data collected, NOT used for tracking, purpose third-party advertising
- [x] ~~Widget deep links dead~~ — simplehabittracker:// scheme registered, single-habit widgets encode habit UUID, .onOpenURL lands on current week
- [x] ~~Rotation layout switch uses deprecated UIDevice.orientation~~ — window-shape (GeometryReader) drives dashboard vs list; handles iPad Split View resizes and stale face-up/down states
- [x] ~~Lost-update race in SharedModelContainer.toggleDay~~ — writes serialized through WidgetStoreWriter actor with cached container; app-side reloads debounced via WidgetReloader
- [x] ~~VersionedSchema/SchemaMigrationPlan V1 baseline~~ — SimpleHabitsSchemaV1 (1.0.0, CloudKit-compatible shape) + migration plan wired into SharedModelContainer.create
- [x] ~~Force-unwrapped app-group container URL~~ — groupContainerURL with assertion + Application Support fallback
- [ ] Perf: per-habit [Date: WeekRecord] dictionary + completedCount helper (streaks, heatmap, stats, calendar)
- [ ] Scoped reloadTimelines(ofKind:) instead of reloadAllTimelines() (6 sites)
- [ ] Wire Product.storekit into shared scheme; add StoreKitTest coverage for PurchaseManager
- [ ] Onboarding: skip button + hide off-screen "Get Started" from accessibility tree

## Shipped

- [x] ~~Widgets (v1.1)~~ — 4 WidgetKit widgets (single today free, week/multi/heatmap premium), interactive toggle, theme sync
- [x] ~~Streak tracking (v1.2)~~ — per-habit flame badge, consecutive weeks meeting weekly target, relative to viewed week

## Small / Polish (v1.2)

- [ ] Forest theme (new 7th theme)
- [ ] Today indicator: themed shapes per theme (not just dot/ring)
- [ ] Theme-aware backgrounds and title colors

## Medium (v1.3+)

- [ ] Notifications / reminders
- [ ] Emoji habit circles — replace dots with emoji pairs (fire/water, rose/wilted, etc.)
- [ ] Smarter ad strategy — rewarded ads for extended free history, A/B test

## Big / Future (v2.0)

- [ ] Apple Health integration
- [ ] Apple Watch companion
- [ ] iPad redesign — optimized layout for iPad screen real estate
- [ ] Shiny effects (SwiftUI Shiny package) as premium bonus
