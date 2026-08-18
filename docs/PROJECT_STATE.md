# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — POLISHED MVP + LOCAL STOREKIT QA BASE GREEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified checkpoint: `f9541c26a4ea63b78c302977a95566827c37b45f`

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

### Monetization

- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Free tier: maximum 5 active purchases.
- Completed purchases do not count against the limit.
- Lifetime Pro unlocks unlimited active purchases.
- No subscription in v1.
- Missing product surfaces a localized error.
- First Lifetime tap loads a missing product and continues the same purchase attempt.
- Purchase/restore operations clear stale errors and expose loading state consistently.

### Local StoreKit testing

- Local configuration committed at `KeepMeter/StoreKit/KeepMeter.storekit`.
- Configuration contains one non-consumable Lifetime Pro product with the exact production product ID.
- Current local test price: 9.99; this is test metadata and does not lock the final App Store price tier.
- DE/EN StoreKit product metadata is present.
- Shared Debug Run scheme references the local StoreKit configuration.
- CI validates JSON syntax, exact product ID and scheme reference before compiling.
- Settings contains a `#if DEBUG` StoreKit QA section showing product ID, loaded state, display price and current entitlement, plus reload/refresh controls.
- Debug-only QA UI is excluded from Release/TestFlight builds.

Important: the local StoreKit environment and scheme are compile/structure validated, but an interactive Xcode purchase sheet has not yet been clicked through from this connector environment. Do not claim Free -> Pro -> restore has been exercised end-to-end until it is actually run in Xcode/Simulator or device.

### Notification hardening

- Dynamic reminder copy uses stable format localization keys.
- DE/EN purchase-name and days-remaining interpolation is fixed.
- Settings reads current `UNAuthorizationStatus`.
- User can request permission from Settings when not determined.
- If denied, Settings offers direct handoff to iOS Settings.
- Notification status refreshes when the app becomes active again.

### Visual system

Polished MVP styling covers Onboarding, Dashboard, Add Purchase, Purchase Detail, Insights, Archive, Settings and Paywall with adaptive backgrounds, material cards, KeepMeter accent/status colors, return-window progress, metric hierarchy, decision hero treatment and Lifetime-first Pro presentation.

Dedicated manual light/dark and accessibility QA remains open.

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
- PR #5 `Add local StoreKit test environment`
- Workflow `32184529919`
- StoreKit configuration validation: SUCCESS
- Full iOS Simulator build: SUCCESS
- Merge `f9541c26a4ea63b78c302977a95566827c37b45f`

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
- visual-polish simulator compile
- StoreKit/reminder hardening compile
- notification-controls compile
- local StoreKit config JSON / product ID / scheme reference
- app compile with StoreKit-enabled shared Debug scheme

Still not explicitly exercised end-to-end:
- physical-device QA
- persistence/relaunch behavior
- actual local-notification delivery on device
- interactive local StoreKit purchase session
- Free-limit -> Lifetime Pro -> restore behavior
- dedicated light/dark QA
- accessibility QA

Release:
- no TestFlight build yet
- no App Store submission yet
- matching Lifetime IAP still needs App Store Connect configuration before sandbox/TestFlight purchase testing

## Still open for MVP

1. Exercise local StoreKit purchase and restore interactively in Xcode/Simulator.
2. Create/configure matching Lifetime IAP in App Store Connect.
3. Persistence/relaunch QA.
4. Notification delivery QA on device.
5. Free-limit / purchase / restore QA.
6. Dedicated light/dark appearance QA and fixes.
7. Accessibility pass.
8. Final visual identity / app icon.
9. Final-enough name/domain/trademark due diligence before public branding.
10. First TestFlight readiness pass and signed archive/upload.

## Naming

Working name: `KeepMeter`.
Status: PROVISIONAL.
Preliminary checks did not reveal an obvious exact-name consumer-app collision, but formal trademark clearance/domain reservation are not recorded yet.

## Immediate next steps

1. Add persistence/relaunch QA support and harden any data-integrity edge cases found.
2. Run source-level light/dark + accessibility hardening and CI gate it.
3. Exercise local StoreKit Free -> Lifetime Pro -> restore interactively when an Xcode runtime is available.
4. Exercise real notification scheduling/delivery on device using Settings diagnostics.
5. Lock icon/public branding after stronger name due diligence.
6. Configure App Store Connect Lifetime IAP and prepare first signed TestFlight build after QA gates are green.
