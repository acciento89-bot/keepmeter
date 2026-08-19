# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — AUTOMATED RUNTIME + ACCESS POLICY GREEN / APPLE + DEVICE QA OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `14f265b4fee61d2be635cb2ba0ed15b994904924`

## Handoff rule

This file is the authoritative ongoing KeepMeter state.

For future work:
1. Read this file first.
2. Inspect current `main`, open PRs and CI.
3. Continue from `Immediate next steps`.
4. Update this file after every major pass.
5. Do not require a parallel App Factory state update for normal KeepMeter development.

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop: **Bought -> Use -> Measure -> Decide before deadline.**

## Locked v1

- Add purchase: name, optional merchant, price, purchase date, user-confirmed return deadline.
- Active purchases ordered by urgency.
- One-tap usage logging.
- Cost per use.
- Return-window countdown/progress.
- Explainable KEEP / REVIEW / RETURN? signal.
- Local return reminders.
- Archive as kept or returned; archived purchases are read-only.
- Insights.
- German + English.
- Free: max 5 active purchases.
- Lifetime Pro: unlimited active purchases, one-time StoreKit 2 non-consumable.
- No subscription in v1.
- No required account/backend/bank/inbox integration.

## Native target

- SwiftUI + SwiftData + UserNotifications + StoreKit 2.
- iOS 17+.
- iPhone only.
- Bundle ID `de.kamilunavo.keepmeter`.
- Marketing version `0.1.0`.
- Build `1`.
- Utilities category.
- Generated Info.plist.

## Product rules / monetization

### DecisionEngine v1

- deadline passed -> REVIEW.
- 0 uses + <=3 days -> RETURN?.
- <=1 use + <=3 days -> REVIEW.
- 0 uses after >=60% of return window -> REVIEW.
- >=3 uses -> KEEP.
- early window -> REVIEW / gather signal.
- otherwise -> REVIEW / more evidence needed.
- cost/use is informational only; no universal value threshold is claimed.

### AccessPolicy

Gate 16 centralized the Free/Pro rule with the product rules instead of keeping a Dashboard magic number.

Single source of truth:
- `AccessPolicy.freeActivePurchaseLimit = 5`.
- Free users may add active purchases while active count <5.
- the sixth active purchase is blocked and routed to Pro.
- completed/archived purchases do not consume a Free slot because only `.active` count is supplied.
- Lifetime Pro bypasses the active-purchase limit.

`ci/ProductRulesSmoke.swift` directly tests the DecisionEngine branches plus Free counts below/at the limit and Pro behavior at high counts.

## Data integrity / persistence

Implemented:
- `Purchase` + `UsageEvent` SwiftData models.
- explicit saves for creation, usage logging and final keep/return actions.
- failed saves roll back and surface localized errors.
- archived items expose no active mutation controls and display stored outcome.
- reminders schedule only after successful save and cancel only after successful archival.

Automated:
- `ci/PersistenceSmoke.swift` writes a real file-backed SwiftData store, destroys the first container, reopens it and verifies IDs, fields, dates, outcome, usage relationship and cost/use.
- booted Simulator runtime proves KeepMeter can install, launch, terminate and relaunch.

Still open:
- physical iPhone force-quit/relaunch with a real test purchase.

## StoreKit / Lifetime Pro

Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.

Implemented:
- local `KeepMeter/StoreKit/KeepMeter.storekit` NonConsumable test product.
- shared Debug scheme references local StoreKit config.
- DE/EN local product metadata.
- DEBUG Settings diagnostics for product, price and entitlement.
- `Transaction.currentEntitlements` refreshes independently of product metadata loading.
- verified `Transaction.updates` handled.
- verified `Transaction.unfinished` handled on load/restore.
- access refresh occurs before `transaction.finish()`.
- unverified transactions never unlock Pro.
- `AppStore.sync()` only behind explicit Restore Purchases.

Still open:
- interactive local Free -> Pro -> Restore session.
- matching App Store Connect Lifetime IAP creation/configuration.
- sandbox/TestFlight purchase + restore session.

## Notifications

Implemented:
- local reminders around entered return date.
- stable DE/EN dynamic format localization.
- Settings exposes authorization state, permission request and iOS Settings handoff.
- status refreshes on app activation.

Still open:
- real scheduled notification delivery on physical device.

## Localization

`ci/localization-preflight.py` is required CI:
- exact EN/DE key parity.
- no duplicates.
- no empty values.
- matching `%@` / `%ld` and other format placeholders.

Gate 13 validated 123 EN/DE keys.

## Privacy manifest

`KeepMeter/PrivacyInfo.xcprivacy` is bundled in the target.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` for app-local `@AppStorage` / UserDefaults preferences.

CI verifies:
- source plist validity and expected structure.
- exact UserDefaults reason.
- Release app contains `PrivacyInfo.xcprivacy`.
- bundled manifest plist-equals source.

Re-audit before release if analytics, crash SDKs, networking/data collection or additional Required Reason APIs are introduced.

## Visual / accessibility / brand

- polished SwiftUI visual system across Onboarding, Dashboard, Add, Detail, Insights, Archive, Settings and Paywall.
- Dynamic Type-adaptive layouts on major screens.
- VoiceOver grouping/hiding applied where appropriate in source.
- KeepMeter blue approximately `#306BF5`; soft blue approximately `#63A1FF`; green reserved for positive/KEEP meaning.
- operational v1 public brand: **KeepMeter**; this is not claimed as formal trademark clearance.
- final custom decision-meter/gauge AppIcon is 1024x1024, opaque and CI-gated.
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in Debug + Release.

### Runtime evidence

Gate 15 workflow `32215165699`:
- real Debug app installed into a booted iPhone Simulator.
- Light + English onboarding launched.
- Dark + German dashboard launched.
- app terminated and relaunched successfully.
- runtime screenshots uploaded as artifact `keepmeter-runtime-screenshots`, artifact ID `9352256830`.
- both representative screenshots were visually inspected; no obvious clipping/localization/contrast regression was found in those covered states.

Still open:
- broader all-important-screen Light/Dark device review.
- physical/runtime VoiceOver pass.
- physical Dynamic Type spot-check.

## App Store release assets / metadata

- final AppIcon: DONE.
- Privacy Manifest baseline: DONE.
- `docs/APP_STORE_RELEASE.md` contains DE/EN listing drafts, screenshot plan and Apple-side checklist.
- no TestFlight build has been uploaded yet.
- no App Store submission yet.
- signed Archive/export/upload not yet exercised.

No App Store Connect / Apple Developer write connector was available when checked, so Apple-side app/IAP creation and signed upload may require authenticated App Store Connect/Xcode interaction.

## Current required CI pipeline

Runner: `macos-26-intel`.

1. StoreKit configuration validation.
2. Release/AppIcon/privacy preflight.
3. EN/DE localization integrity.
4. ProductRules/DecisionEngine/AccessPolicy smoke.
5. file-backed SwiftData reopen smoke.
6. Debug Simulator build.
7. booted iPhone Simulator install + Light/EN + Dark/DE + terminate/relaunch runtime smoke.
8. runtime screenshot artifact upload.
9. Release Simulator build.
10. built-app Privacy Manifest verification.

Workflow concurrency cancels stale runs for the same ref. `ci/simulator-runtime-smoke.py` uses bounded CoreSimulator command timeouts, waits for boot services, and checks the installed app container when `simctl install` returns late.

## Verified gates

1. PR #1 — Functional MVP — workflow `32178808223` — merge `bf024336455d2a65da1e7d5f25ac87f142a3de8d` — GREEN.
2. PR #2 — Visual polish — workflow `32179763750` — merge `45c53308ae41fc38eec5049c0181d4b0d7ede42b` — GREEN.
3. PR #3 — StoreKit/reminder hardening — workflow `32182015862` — merge `0ec1e7b87fb3148462fcdc923770684e9bf67f1f` — GREEN.
4. PR #4 — Notification QA controls — workflow `32182418696` — merge `e82813b2f53677112700c5f0cdbcb0db6a9402c7` — GREEN.
5. PR #5 — Local StoreKit environment — workflow `32184529919` — merge `f9541c26a4ea63b78c302977a95566827c37b45f` — GREEN.
6. PR #6 — Data integrity/accessibility — workflow `32185398795` — merge `f3718152acbd7b51ba90bbb399e3de6fc1116d64` — GREEN.
7. PR #7 — File-backed SwiftData reopen — workflow `32186180485` — merge `2b93368f084ccf4808a0fa2a5e68c5d7dc51bc0c` — GREEN.
8. PR #8 — Release compile — workflow `32186439191` — merge `dad79a620f375ed2c5eaa9ce4d40784130aab164` — GREEN.
9. PR #9 — App Store release preflight — workflow `32186964254` — merge `5582461de995c8954f44b78c3314b3dbf2ee22c2` — GREEN.
10. PR #10 — v1 brand lock — workflow `32187367731` — merge `eaadd52c37ce38e98e3ad96a55bda4eaea84291a` — GREEN.
11. PR #11 — Final AppIcon hard gate — workflow `32189137123` — merge `cedc90a883713683217f663485a6d8f2e09fd63a` — GREEN.
12. PR #12 — Production StoreKit entitlement recovery — workflow `32189569075` — merge `56f501c4f220032ba5fb3ab88dd409b94c5524b6` — GREEN.
13. PR #13 — Product rules + localization — workflow `32212716880` — merge `fe88224b38011d25934b49a1edb2fc2030425306` — GREEN.
14. PR #14 — Required-reason Privacy Manifest — workflow `32212975137` — merge `223eb041a0e4f306fd5dc0c5ed29deb7f12cd197` — GREEN.
15. PR #15 — Booted Simulator runtime + screenshots + relaunch — workflow `32215165699` — merge `9c5b33bf0a0123afe243a0b32bd4d0139537cd82` — GREEN.
16. PR #16 — Central Free/Pro AccessPolicy — workflow `32216276685` — merge `14f265b4fee61d2be635cb2ba0ed15b994904924` — GREEN.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Remaining release gates

- App Store Connect app record verification/creation.
- Lifetime IAP `de.kamilunavo.keepmeter.pro.lifetime` creation + metadata + final price.
- interactive local StoreKit purchase/restore.
- physical-device purchase persistence / force-quit-relaunch.
- real notification delivery.
- broader Light/Dark + Dynamic Type device check.
- VoiceOver runtime QA.
- final support/privacy URLs and App Privacy answers.
- signed Release Archive.
- first TestFlight upload and sandbox Lifetime Pro/restore test.

## Immediate next steps

1. Expand Simulator runtime evidence to a populated purchase/dashboard/detail state without shipping QA behavior in Release.
2. Prepare exact App Store Connect Lifetime IAP metadata and reviewer-facing purchase information.
3. Perform remaining Apple/device gates when authenticated App Store Connect/Xcode/device access is available.
4. Only then create the first signed TestFlight build; do not burn intermediate TestFlight build numbers.
