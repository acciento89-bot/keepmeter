# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — POLISHED MVP BUILD GREEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified checkpoint: `45c53308ae41fc38eec5049c0181d4b0d7ede42b`

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

## Implemented and compiling

### Core product

- Native `KeepMeter.xcodeproj` and shared scheme.
- Provisional bundle ID `de.kamilunavo.keepmeter`.
- Version scaffold `0.1.0 (1)`.
- SwiftData `Purchase` and `UsageEvent` models.
- Active / kept / returned outcomes.
- Cost-per-use and return-window calculations.
- Deterministic, explainable KEEP / REVIEW / RETURN? engine.
- Dashboard, Add Purchase, Purchase Detail and Archive.
- One-tap usage logging.
- Local return reminders at 3 days, 1 day and deadline day when applicable.
- Reminder cancellation when a purchase is completed.
- 3-page onboarding.
- Main tabs: Active / Insights / Archive / Settings.
- Insights with tracked value, total uses, average cost/use, open decisions, kept/returned counts and best-value item.

### Monetization

- StoreKit 2 entitlement service.
- Current product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Free tier: maximum 5 active purchases.
- Completed purchases do not count against the active cap.
- Lifetime Pro: unlimited active purchases.
- Purchase and restore plumbing compile.
- No subscription in v1.

### Visual system — first polish pass complete

PR #2 applied the first coherent KeepMeter visual language across the complete MVP surface:

- adaptive branded app background
- primary KeepMeter blue accent plus semantic success/warning/return colors
- reusable material-card treatment with restrained borders/shadows
- redesigned first-launch onboarding
- redesigned decision dashboard and purchase cards
- visible return-window progress on active purchases
- clearer metric hierarchy for uses, cost/use and days remaining
- redesigned purchase-detail decision hero
- prominent one-tap usage action
- redesigned final keep/return decision area
- polished Insights dashboard
- polished Archive
- polished Add Purchase flow
- polished Settings / Pro status card
- Lifetime-first Pro paywall emphasizing one-time purchase / no subscription
- dashboard success haptic after logging a use
- additional DE/EN visual-copy localization

The styling uses system-aware backgrounds/materials and semantic colors so it is structurally compatible with light and dark appearance. A dedicated manual light/dark QA pass is still open.

## Verified build gates

### Gate 1 — functional MVP

- Validation PR: #1 `Validate current KeepMeter MVP build`.
- Workflow run: `32178808223`.
- Result: SUCCESS.
- Merge checkpoint: `bf024336455d2a65da1e7d5f25ac87f142a3de8d`.

### Gate 2 — visual polish

- Branch: `agent/visual-polish-v1`.
- PR: #2 `Polish KeepMeter MVP visual system`.
- 11 changed files, ~1,200 additions during the pass.
- Workflow run: `32179763750`.
- Full iOS Simulator `xcodebuild`: SUCCESS.
- PR #2 squash-merged.
- Current merge checkpoint: `45c53308ae41fc38eec5049c0181d4b0d7ede42b`.

Future major source passes must continue to use CI as a regression gate before merge/TestFlight.

## Decision-engine v1

Current conservative prototype rules:

- deadline passed -> REVIEW
- zero uses and <= 3 days remaining -> RETURN?
- <= 1 use and <= 3 days remaining -> REVIEW
- zero uses after >= 60% of the return window -> REVIEW
- >= 3 logged uses -> KEEP signal
- early in the return window -> REVIEW / keep collecting signal
- otherwise -> REVIEW / more signal needed

The UI explains the reason. Cost per use is displayed, but no universal monetary threshold pretends to define personal value.

## Guardrails

- No account/backend for core v1.
- No bank connection.
- No inbox scraping.
- No generic receipt/warranty-vault positioning.
- No forced subscription.
- No opaque AI recommendation.
- No claim that a user-entered return date is a guaranteed legal right; merchant policy/statutory rights may differ.

## Build / QA status

- Functional CI simulator build: GREEN.
- Visual-polish CI simulator build: GREEN.
- No physical-device QA yet.
- Persistence/relaunch behavior has not yet been explicitly exercised.
- Notification permission/delivery behavior has not yet been explicitly exercised.
- StoreKit local/sandbox purchase flow has not yet been exercised.
- No TestFlight build uploaded yet.
- No App Store submission yet.

## Still open for MVP

- Visual identity / final app icon.
- Dedicated light/dark appearance QA and fixes.
- Dynamic notification strings: full DE/EN formatting cleanup.
- StoreKit local `.storekit` test configuration.
- Create/configure Lifetime IAP in App Store Connect.
- Persistence/relaunch QA.
- Notification permission/behavior QA.
- Free-limit / purchase / restore QA.
- Accessibility pass.
- Final-enough name/domain/trademark due diligence before public branding.
- First TestFlight readiness pass and signed archive/upload.

## Naming

Working name: `KeepMeter`.

Status: PROVISIONAL. Preliminary market checks did not reveal an obvious exact-name consumer-app collision, but this is not formal trademark clearance and no domain reservation is recorded yet.

## Immediate next steps

1. Add local StoreKit test configuration and exercise free -> Lifetime Pro -> restore behavior.
2. QA persistence/relaunch and notification scheduling/delivery.
3. Run dedicated light/dark and accessibility passes on the polished UI.
4. Establish final icon/visual identity once naming is strong enough to keep.
5. Perform stronger name/domain/trademark due diligence before App Store branding is locked.
6. Prepare first signed TestFlight build only after these QA gates are green.

## Cross-project handoff

The master App Factory status lives in `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md` and must be updated after every major KeepMeter pass.
