# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — FIRST GREEN MVP BUILD
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified checkpoint: `bf024336455d2a65da1e7d5f25ac87f142a3de8d`
Validation PR: `#1 Validate current KeepMeter MVP build` — merged
Validated workflow run: `32178808223` — SUCCESS

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
12. First-launch onboarding explains the product loop.
13. Lightweight Insights summarizes tracked value, usage and decisions.
14. Settings exposes Pro status, restore flow, privacy messaging and onboarding reset.

## Native stack

- SwiftUI
- SwiftData
- UserNotifications
- StoreKit 2
- iOS 17+
- GitHub Actions iOS Simulator build validation

## Current implementation

### Implemented and compiling

- Native `KeepMeter.xcodeproj`.
- Shared Xcode scheme.
- Generated Info.plist configuration through build settings.
- Provisional bundle ID: `de.kamilunavo.keepmeter`.
- App version scaffold: `0.1.0 (1)`.
- `Purchase` SwiftData model.
- `UsageEvent` SwiftData model.
- Active / kept / returned outcomes.
- Cost-per-use calculation.
- Return-window remaining-days calculation.
- Return-window elapsed-ratio calculation.
- Deterministic `DecisionEngine` with KEEP / REVIEW / RETURN? signals.
- Decision reasons shown to the user; recommendation is not opaque AI.
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
- Lifetime Pro paywall when the cap is reached.
- 3-page first-launch onboarding.
- Main tab shell: Active / Insights / Archive / Settings.
- Insights dashboard with tracked value, total uses, average cost/use, open decisions, kept/returned counts and best-value item.
- Settings / Pro management entry.
- Local-first privacy explanation in Settings.
- Onboarding can be shown again from Settings.
- English localization resource.
- German localization resource.
- `Combine` import fix for `EntitlementStore` state publishing.
- GitHub Actions workflow at `.github/workflows/ios-build.yml` for an unsigned iOS Simulator build.

## Verified build milestone

The first real CI compile is confirmed green.

Validation method:

1. Created branch `agent/ci-validation` from the current `main` implementation.
2. Opened PR #1 so the existing `pull_request` workflow could be observed through the connected GitHub interface.
3. GitHub Actions run `32178808223` executed job `build`.
4. `xcodebuild` compiled `KeepMeter.xcodeproj` / scheme `KeepMeter` for generic iOS Simulator with code signing disabled.
5. All workflow steps completed successfully.
6. PR #1 was squash-merged.
7. Resulting merge commit: `bf024336455d2a65da1e7d5f25ac87f142a3de8d`.

This is the first objective green-build gate for App Factory #001.

## Monetization implementation

Current code product ID:

`de.kamilunavo.keepmeter.pro.lifetime`

Current behavior:

- Free: maximum 5 active tracked purchases.
- Archived / completed purchases do not count against the active cap.
- Pro: unlimited active purchases.
- Pro purchase model: one-time Lifetime unlock.
- No subscription in v1.

The StoreKit code compiles, but the matching In-App Purchase still needs local StoreKit test configuration and App Store Connect creation/configuration before real purchase testing.

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

- First CI iOS Simulator build: GREEN.
- PR validation path confirmed usable for future compile checks.
- Source currently compiles with Onboarding, Insights, Settings and StoreKit plumbing included.
- No physical-device QA yet.
- Persistence/relaunch behavior has not yet been explicitly exercised.
- Notification permission/delivery behavior has not yet been explicitly exercised.
- StoreKit sandbox/local product flow has not yet been exercised.
- No TestFlight build uploaded yet.
- No App Store submission yet.

## Still open for MVP

- First high-polish visual system across Dashboard / Detail / Insights / Settings.
- Visual identity and app icon.
- Dynamic notification strings: full DE/EN formatting cleanup.
- StoreKit local `.storekit` test configuration.
- Create/configure Lifetime IAP in App Store Connect.
- Persistence/relaunch QA.
- Notification permission/behavior QA.
- Free-limit / purchase / restore QA.
- Light/dark-mode polish.
- Accessibility pass.
- Final-enough name/domain/trademark due diligence before public branding.
- First TestFlight readiness pass and signed archive/upload.

## Naming

Working name: `KeepMeter`.

Status: PROVISIONAL. Preliminary market checks did not reveal an obvious exact-name consumer-app collision, but this is not formal trademark clearance and no domain reservation is recorded yet.

## Immediate next steps

1. Apply the first coherent high-polish visual system while preserving the now-green architecture.
2. Create an app-icon / visual-identity direction once the UI language is coherent.
3. Add local StoreKit test configuration and exercise the free-to-Pro path.
4. QA persistence, reminders and core decision flow.
5. Complete light/dark and accessibility passes.
6. Perform stronger name/domain/trademark due diligence before App Store branding is locked.
7. Prepare first TestFlight build only after the QA gates above are green.

## Cross-project handoff

The master App Factory status lives in `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md` and must be updated after every major KeepMeter pass.
