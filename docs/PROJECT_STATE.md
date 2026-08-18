# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — FIRST NATIVE IMPLEMENTATION PASS COMPLETE
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Latest implementation commit at this checkpoint: `92e2ea4ef203b16eadf9f2d54090213db81815c6`

## Product thesis

KeepMeter answers one focused question:

> Is this purchase actually worth keeping before the return window closes?

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

## Locked MVP

1. Add a purchase with name, price, purchase date and return deadline.
2. Show active purchases ordered by urgency.
3. Log a usage with one tap.
4. Calculate cost per use.
5. Show days remaining in the return window.
6. Produce an explainable KEEP / REVIEW / RETURN recommendation.
7. Schedule local return-deadline reminders.
8. Archive purchases as kept or returned.
9. German + English from the first build.
10. Free tier: up to 5 active purchases.
11. Lifetime Pro via StoreKit 2; no subscription in v1.

## Native stack

- SwiftUI
- SwiftData
- UserNotifications
- StoreKit 2
- iOS 17+
- GitHub Actions simulator-build workflow

## Current implementation

### Implemented

- Native `KeepMeter.xcodeproj` created.
- Shared Xcode scheme created.
- Generated Info.plist configuration added through build settings.
- Provisional bundle ID: `de.kamilunavo.keepmeter`.
- App version scaffold: `0.1.0 (1)`.
- `Purchase` SwiftData model.
- `UsageEvent` SwiftData model.
- Active / kept / returned outcomes.
- Cost-per-use calculation.
- Return-window remaining-days calculation.
- Return-window elapsed-ratio calculation.
- Deterministic `DecisionEngine` with KEEP / REVIEW / RETURN? signals.
- Decision reasons are shown to the user; recommendation is not opaque AI.
- Home / Decision Dashboard.
- Add Purchase flow.
- Purchase Detail screen.
- One-tap usage logging.
- Archive screen.
- Mark purchase as kept or returned.
- Local return reminders at 3 days, 1 day and deadline day when applicable.
- Notification cancellation when a purchase is completed.
- StoreKit 2 entitlement service.
- Lifetime Pro purchase / restore plumbing.
- Free-tier cap of 5 active purchases.
- Lifetime Pro paywall shown when the cap is reached.
- English localization resource.
- German localization resource.
- GitHub Actions workflow at `.github/workflows/ios-build.yml` for an unsigned iOS Simulator build.

### Monetization implementation

Current code product ID:

`de.kamilunavo.keepmeter.pro.lifetime`

Current behavior:

- Free: maximum 5 active tracked purchases.
- Archived / completed purchases do not count against the active cap.
- Pro: unlimited active purchases.
- Pro purchase model: one-time Lifetime unlock.
- No subscription in v1.

The StoreKit code exists, but the matching In-App Purchase still needs to be created/configured in App Store Connect before real purchase testing.

## Decision-engine v1

The recommendation is deliberately transparent and conservative.

Current rules include:

- deadline already passed -> REVIEW
- zero uses with <= 3 days left -> RETURN?
- <= 1 use with <= 3 days left -> REVIEW
- zero uses after >= 60% of the return window -> REVIEW
- >= 3 logged uses -> KEEP signal
- early in the return window -> REVIEW / keep collecting signal
- otherwise -> REVIEW / more signal needed

Cost per use is displayed continuously. The current engine does not pretend that a universal monetary threshold determines personal value.

## Guardrails

- No account/backend for core v1.
- No bank connection.
- No inbox scraping.
- No generic receipt/warranty-vault positioning.
- No forced subscription.
- No opaque AI recommendation.
- No claim that a user-entered return date is a guaranteed legal right; merchant policy/statutory rights may differ.

## Current build / QA status

- Xcode project and shared scheme are committed.
- A real GitHub Actions iOS Simulator build workflow is committed.
- The connected GitHub interface used in this chat does not expose push-triggered workflow-run listing, so the CI result is not yet verified from this environment.
- No simulator/device QA has been completed yet.
- No TestFlight build has been uploaded yet.

## Still open for MVP

- Onboarding (max 3 cards).
- Lightweight Insights screen.
- Settings / explicit Pro management entry point.
- Visual identity / app icon / first high-polish design pass.
- Dynamic notification strings need full DE/EN formatting cleanup.
- StoreKit local test configuration and App Store Connect IAP setup.
- Persistence/relaunch QA.
- Notification permission/behavior QA.
- Light/dark-mode polish.
- Accessibility pass.
- Final-enough name/trademark/domain due diligence before public branding.
- First successful simulator build validation.
- First TestFlight readiness pass.

## Naming

Working name: `KeepMeter`.

Status: PROVISIONAL. Preliminary market checks did not reveal an obvious exact-name consumer-app collision, but this is not formal trademark clearance and no domain reservation is recorded yet.

## Immediate next steps

1. Get the first simulator build green and fix any Xcode/Swift compile issues.
2. Add onboarding and Settings/Pro entry point.
3. Add first polished visual system and app icon direction.
4. Add StoreKit test configuration and create the Lifetime product in App Store Connect when ready.
5. QA persistence, reminders, free limit and restore flow.
6. Perform final name/domain/trademark due diligence before App Store branding is locked.
7. Prepare first TestFlight build only after the core loop is stable.

## Cross-project handoff

The master App Factory status lives in `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md` and must be updated after every major KeepMeter pass.
