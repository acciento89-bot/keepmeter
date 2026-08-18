# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — PERSISTENCE + RELEASE BUILD GATES GREEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified checkpoint: `dad79a620f375ed2c5eaa9ce4d40784130aab164`

## Handoff rule

This file is the authoritative and sufficient ongoing project state for KeepMeter.

For future KeepMeter work:

1. Read this file first.
2. Inspect current `main`, open PRs and CI state.
3. Continue from the recorded next steps.
4. Update this file after each major pass.
5. Do not require a parallel update in the external App Factory master repository for normal KeepMeter development.

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop: **Bought -> Use -> Measure -> Decide before deadline.**

## Locked MVP

- Add purchase with name, price, purchase date and return deadline.
- Active purchases ordered by urgency.
- One-tap usage logging.
- Cost per use.
- Return-window countdown.
- Explainable KEEP / REVIEW / RETURN? signal.
- Local return reminders.
- Archive as kept or returned.
- German + English.
- Free tier: max 5 active purchases.
- Lifetime Pro via StoreKit 2; no subscription in v1.
- 3-page onboarding.
- Lightweight Insights.
- Settings with Pro/restore, privacy, notification controls and onboarding reset.

## Native stack

- SwiftUI
- SwiftData
- UserNotifications
- StoreKit 2
- iOS 17+
- GitHub Actions simulator-build validation

## Implemented and compiling

### Core product

- Native `KeepMeter.xcodeproj` + shared scheme.
- Provisional bundle ID `de.kamilunavo.keepmeter`.
- Version scaffold `0.1.0 (1)`.
- `Purchase` + `UsageEvent` SwiftData models.
- Active / kept / returned outcomes.
- Dashboard, Add Purchase, Purchase Detail, Archive.
- Cost-per-use and return-window calculations.
- Deterministic explainable DecisionEngine.
- Local reminders at 3 days, 1 day and deadline day where applicable.
- Reminder cancellation when a purchase is completed.
- Main tabs: Active / Insights / Archive / Settings.

### Data-integrity / persistence hardening

- Archived purchases are read-only in Purchase Detail.
- Archived purchases no longer show active usage logging or final-decision controls.
- Archived purchases no longer display a newly recalculated live DecisionEngine recommendation; the stored final outcome is shown instead.
- Active-state guards protect usage/final-decision mutations even if UI state regresses later.
- Creating a purchase no longer swallows SwiftData save failures.
- Failed creation saves roll back and show a localized error.
- Usage logging on Dashboard and Purchase Detail now saves explicitly; failed saves roll back and surface a localized error instead of showing false success.
- Final keep/return decisions now save explicitly and roll back on failure.
- Return reminders are scheduled only after a purchase successfully persists.
- Existing return reminders are cancelled only after the final archived outcome successfully persists.
- `ci/PersistenceSmoke.swift` uses the real `Purchase` and `UsageEvent` models with a file-backed SwiftData store.
- CI writes a purchase, usage relationship and archived outcome, destroys the first container, reopens the same store, then verifies IDs, fields, dates, relationship, outcome and derived cost-per-use.

Important: executable file-backed persistence reopen is CI-green. A physical iPhone terminate/relaunch session remains a separate runtime QA gate and must not be claimed as completed yet.

### Monetization / local StoreKit testing

- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Free tier: maximum 5 active purchases; completed purchases do not count.
- Lifetime Pro unlocks unlimited active purchases; no subscription in v1.
- Local configuration: `KeepMeter/StoreKit/KeepMeter.storekit`.
- One non-consumable Lifetime product with exact production product ID.
- Local test price: 9.99; not a locked App Store price tier.
- DE/EN StoreKit metadata.
- Shared Debug Run scheme references local StoreKit configuration.
- CI validates JSON, product ID and scheme reference.
- DEBUG-only Settings diagnostics show product ID, loaded state, test price, current entitlement and reload/refresh controls.
- Missing product and first-tap loading behavior are hardened.

Important: local StoreKit is structurally/compile validated, but the interactive Free -> Pro -> restore sequence has not yet been clicked through in Xcode/Simulator/device.

### Notifications

- Dynamic reminder copy uses stable format localization keys.
- DE/EN purchase-name and days-remaining interpolation is fixed.
- Settings reads current `UNAuthorizationStatus`.
- Permission can be requested from Settings.
- Denied permission offers direct iOS Settings handoff.
- Status refreshes when the app becomes active again.

### Visual / accessibility hardening

- Polished visual language covers Onboarding, Dashboard, Add Purchase, Purchase Detail, Insights, Archive, Settings and Paywall.
- Dashboard, Purchase Detail, Archive and Insights switch to stacked/adaptive layouts at Accessibility Dynamic Type sizes.
- Insights grid reduces from two columns to one for accessibility sizes.
- Onboarding reduces decorative artwork footprint at accessibility sizes so content remains readable.
- Paywall purchase layout adapts at accessibility sizes.
- Fixed-height text controls were replaced with content-driven vertical padding where clipping was possible.
- Decorative icons are hidden from VoiceOver where appropriate.
- Major cards/metrics use improved accessibility grouping.
- Return-window progress exposes an accessibility value.
- Runtime-count localization in the dashboard uses a stable format key.

A real-device VoiceOver and visual light/dark inspection is still open; do not claim runtime accessibility QA is complete yet.

### Release build validation

- CI now compiles both Debug and Release configurations for the generic iOS Simulator.
- Release compilation validates code paths with DEBUG-only QA UI excluded.
- StoreKit configuration validation and SwiftData persistence reopen run before both app builds.
- Release simulator compilation is not a signed Archive and does not replace the first real TestFlight archive/upload gate.

## Verified build gates

### Gate 1 — Functional MVP
- PR #1
- Workflow `32178808223`
- SUCCESS
- Merge `bf024336455d2a65da1e7d5f25ac87f142a3de8d`

### Gate 2 — Visual polish
- PR #2
- Workflow `32179763750`
- SUCCESS
- Merge `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

### Gate 3 — StoreKit / reminder hardening
- PR #3
- Workflow `32182015862`
- SUCCESS
- Merge `0ec1e7b87fb3148462fcdc923770684e9bf67f1f`

### Gate 4 — Notification QA controls
- PR #4
- Workflow `32182418696`
- SUCCESS
- Merge `e82813b2f53677112700c5f0cdbcb0db6a9402c7`

### Gate 5 — Local StoreKit test environment
- PR #5
- Workflow `32184529919`
- StoreKit validation + full simulator build: SUCCESS
- Merge `f9541c26a4ea63b78c302977a95566827c37b45f`

### Gate 6 — Data integrity / accessibility hardening
- PR #6 `Harden data integrity and accessibility`
- Workflow `32185398795`
- StoreKit validation: SUCCESS
- Full iOS Simulator build: SUCCESS
- Merge `f3718152acbd7b51ba90bbb399e3de6fc1116d64`

### Gate 7 — SwiftData persistence reopen
- PR #7 `Add SwiftData persistence reopen gate`
- Workflow `32186180485`
- StoreKit validation: SUCCESS
- File-backed SwiftData write -> container destroy -> reopen verification: SUCCESS
- Full iOS Simulator Debug build: SUCCESS
- Merge `2b93368f084ccf4808a0fa2a5e68c5d7dc51bc0c`

### Gate 8 — Release configuration compile
- PR #8 `Add Release configuration build gate`
- Workflow `32186439191`
- StoreKit validation: SUCCESS
- SwiftData persistence reopen: SUCCESS
- Full iOS Simulator Debug build: SUCCESS
- Full iOS Simulator Release build: SUCCESS
- Merge `dad79a620f375ed2c5eaa9ce4d40784130aab164`

Major source passes must remain CI-green before merge/TestFlight.

## DecisionEngine v1

- deadline passed -> REVIEW
- zero uses and <= 3 days remaining -> RETURN?
- <= 1 use and <= 3 days remaining -> REVIEW
- zero uses after >= 60% of return window -> REVIEW
- >= 3 logged uses -> KEEP signal
- early window -> REVIEW / collect more signal
- otherwise -> REVIEW / more evidence needed

Cost per use is informative only; it does not pretend a universal price threshold defines personal value.

## Guardrails

- No account/backend for core v1.
- No bank connection.
- No inbox scraping.
- No generic receipt/warranty-vault positioning.
- No forced subscription.
- No opaque AI recommendation.
- User-entered return dates are informational and not represented as guaranteed legal rights.

## QA / release status

GREEN / STRUCTURALLY VALIDATED:
- functional simulator compile
- full visual-polish compile
- StoreKit/reminder hardening compile
- notification-controls compile
- local StoreKit config / product ID / scheme validation
- data-integrity + Dynamic Type/accessibility source hardening compile
- file-backed SwiftData persistence write/reopen verification
- mutation save failures rollback instead of silently succeeding
- full Debug simulator compilation
- full Release simulator compilation

Still not explicitly exercised end-to-end:
- physical-device QA
- physical terminate/relaunch persistence behavior
- actual local-notification delivery on device
- interactive local StoreKit purchase session
- Free-limit -> Lifetime Pro -> restore flow
- visual light/dark inspection on runtime
- VoiceOver runtime QA

Release:
- no TestFlight build yet
- no App Store submission yet
- matching Lifetime IAP still needs App Store Connect configuration before sandbox/TestFlight purchase testing
- signed Archive/export/upload has not yet been exercised

## Naming

Working name: `KeepMeter`.
Status: PROVISIONAL.
A stronger web exact-name check on 2026-08-18 did not surface an obvious exact consumer-app/software result in the searches performed. EUIPO itself recommends checking identical and similar marks in TMview/eSearch before filing; search-engine absence is not formal trademark clearance. Formal EUIPO/DPMA/domain clearance is still not recorded and the public name is not locked.

## Still open for MVP

1. Audit and close App Store release asset/metadata blockers, especially final app icon and target configuration.
2. Exercise local StoreKit purchase and restore interactively in Xcode/Simulator.
3. Create/configure matching Lifetime IAP in App Store Connect.
4. Physical terminate/relaunch persistence QA.
5. Notification delivery QA on device.
6. Free-limit / purchase / restore runtime QA.
7. Dedicated runtime light/dark inspection and fixes.
8. VoiceOver runtime QA.
9. Final visual identity / app icon.
10. Formal-enough EUIPO/DPMA/domain due diligence before public branding.
11. First signed TestFlight archive/upload.

## Immediate next steps

1. Audit current Release output and Xcode target for AppIcon/Info.plist/version/build warnings and missing release assets.
2. Continue naming/domain/trademark due diligence far enough to lock public branding.
3. Establish final app icon / visual identity after the name is sufficiently safe.
4. Configure Lifetime IAP in App Store Connect.
5. Exercise StoreKit, persistence and notification flows on Xcode/device runtime.
6. Perform final light/dark + VoiceOver runtime inspection.
7. Prepare the first signed TestFlight build only after those runtime gates are green.
