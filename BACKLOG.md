# Simple Habits Backlog

## Tech Debt / Hardening (from 2026-07 health check, full reports in scratch/)

- [x] ~~Migration decode failure silently deletes legacy data~~ — retry instead of marking complete
- [x] ~~CloudKit-incompatible @Model schema~~ — inline defaults on Habit/WeekRecord (fixes iCloud Sync crash loop)
- [x] ~~ATT missing despite AdMob + privacy policy promising it~~ — ATT request gates MobileAds start
- [x] ~~VoiceOver can't reach day-toggle circles~~ — label/value/action on HabitRowView circles
- [x] ~~ITSAppUsesNonExemptEncryption missing~~
- [x] ~~Reconcile ads privacy story~~ — decision 2026-07-11: NO ATT prompt, non-personalized ads only (npa=1 on every request via AdManager.nonPersonalizedRequest). ATT code + NSUserTrackingUsageDescription removed; manifest: tracking=false, DeviceID/AdvertisingData declared non-tracking; widget extension has its own manifest (CA92.1). REMAINING MANUAL STEP: ASC questionnaire — Device ID + Advertising Data collected, NOT used for tracking, purpose third-party advertising
- [x] ~~Widget deep links dead~~ — simplehabittracker:// scheme registered, single-habit widgets encode habit UUID, .onOpenURL lands on current week
- [ ] Rotation layout switch uses deprecated UIDevice.orientation, destroys state; no iPad Split View handling
- [x] ~~Lost-update race in SharedModelContainer.toggleDay~~ — writes serialized through WidgetStoreWriter actor with cached container; app-side reloads debounced via WidgetReloader
- [ ] VersionedSchema/SchemaMigrationPlan V1 baseline
- [ ] Force-unwrapped app-group container URL (SharedModelContainer)
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
