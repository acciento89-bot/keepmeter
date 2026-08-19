# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — SIMULATOR RUNTIME GATE GREEN / APPLE + DEVICE QA OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `9c5b33bf0a0123afe243a0b32bd4d0139537cd82`

## Handoff rule

This file is the authoritative ongoing project state for KeepMeter.

For future KeepMeter work:
1. Read this file first.
2. Inspect current `main`, open PRs and CI.
3. Continue from the recorded next steps.
4. Update this file after every major pass.
5. Normal KeepMeter work is documented here; no parallel App Factory state update is required.

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop: **Bought -> Use -> Measure -> Decide before deadline.**

## Locked v1 product

- Add purchase with name, price, purchase date and user-confirmed return deadline.
- Active purchases ordered by urgency.
- One-tap usage logging.
- Cost per use.
- Return-window countdown/progress.
- Explainable KEEP / REVIEW / RETURN? signal.
- Local return reminders.
- Archive as kept or returned.
- German + English.
- Free tier: maximum 5 active purchases.
- Lifetime Pro: unlimited active purchases via StoreKit 2 non-consumable.
- No subscription in v1.
- 3-page onboarding.
- Lightweight Insights.
- Settings with Pro/restore, privacy, notification controls and onboarding reset.

## Native stack / release target

- SwiftUI + SwiftData + UserNotifications + StoreKit 2.
- iOS 17+, iPhone target.
- Bundle ID: `de.kamilunavo.keepmeter`.
- Marketing version: `0.1.0`.
- Build: `1`.
- App category: Utilities.
- Generated Info.plist.
- CI currently runs on `macos-26-intel` so a real iPhone Simulator can be booted in addition to build-time validation.

## Data integrity / persistence

Implemented and automated:
- `Purchase` + `UsageEvent` SwiftData models.
- Active / kept / returned outcomes.
- Archived purchases are read-only and expose no active mutation controls.
- Archived purchases show the stored final outcome instead of a newly recalculated recommendation.
- Active-state guards protect mutations.
- Creation, usage logging and final keep/return actions explicitly save.
- Failed saves roll back and surface localized errors.
- Return reminders are scheduled only after a successful purchase save.
- Existing reminders are cancelled only after final archived state persists.
- `ci/PersistenceSmoke.swift` writes a real file-backed SwiftData store, destroys the first container, reopens it and verifies IDs, fields, dates, outcome, usage relationship and cost-per-use.

Validated:
- file-backed SwiftData write -> destroy container -> reopen gate is GREEN.
- KeepMeter can be installed, launched, terminated and relaunched on a booted iPhone Simulator.

Still open:
- physical iPhone force-quit -> relaunch persistence session with real user-created data.

## DecisionEngine / product rule regression gate

`ci/ProductRulesSmoke.swift` now executes the locked v1 rules instead of relying only on source review.

Covered:
- expired deadline -> REVIEW / deadlinePassed.
- zero uses and <=3 days -> RETURN? / unusedUrgent.
- <=1 use and <=3 days -> REVIEW / lightlyUsedUrgent.
- zero uses after >=60% return window -> REVIEW / unusedLateWindow.
- >=3 uses -> KEEP / repeatedUse.
- early-window REVIEW branch.
- needs-more-signal REVIEW branch.
- cost-per-use calculation.
- invalid/non-positive return-window clamping.
- v1 free-tier contract remains 5 active purchases before Paywall/Add blocking.

Cost per use remains informational only; KeepMeter does not claim a universal monetary threshold defines personal value.

## Localization regression gate

`ci/localization-preflight.py` is a required CI gate.

It validates:
- exact EN/DE localization-key parity.
- no duplicate keys.
- no empty values.
- matching dynamic format placeholders such as `%@` / `%ld` across languages.

Gate 13 validated 123 EN/DE keys.

## StoreKit / monetization

Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`.

Implemented:
- Free limit is 5 active purchases; completed purchases do not count.
- Lifetime Pro unlocks unlimited active purchases.
- Local StoreKit configuration: `KeepMeter/StoreKit/KeepMeter.storekit`.
- Local product type: NonConsumable.
- Local test price: 9.99; final App Store pricing is not locked by the test config.
- DE/EN local product metadata exists.
- Shared Debug scheme references the local StoreKit configuration.
- CI validates StoreKit JSON, exact product ID and scheme reference.
- DEBUG-only Settings diagnostics expose product ID, loaded state, test price, entitlement and reload/refresh controls.
- Missing-product / first-tap loading behavior is hardened.

Production hardening:
- `Transaction.currentEntitlements` refreshes independently of `Product.products(for:)`.
- existing Lifetime Pro entitlement is not lost when product metadata loading fails temporarily.
- verified transactions refresh paid access before `transaction.finish()`.
- `Transaction.updates` is listened to for the app lifetime.
- verified `Transaction.unfinished` Lifetime transactions are processed during load/restore.
- unverified transactions never unlock Pro.
- `AppStore.sync()` remains behind explicit Restore Purchases only.
- paywall contains no open-ended promise about unspecified future features.

Still open:
- interactive local StoreKit Free -> Pro -> restore session.
- App Store Connect Lifetime IAP creation/configuration.
- sandbox/TestFlight purchase + entitlement + restore session.

## Notifications

Implemented:
- local reminders around the user-entered return deadline.
- stable DE/EN format localization for dynamic reminder copy.
- Settings reads current `UNAuthorizationStatus`.
- permission can be requested from Settings.
- denied state offers iOS Settings handoff.
- notification status refreshes when app becomes active.

Still open:
- real scheduled local-notification delivery on a physical device.

## Privacy manifest / App Privacy baseline

`KeepMeter/PrivacyInfo.xcprivacy` is included in the app target and Release product.

Current v1 declarations:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for the current local-only core architecture.
- Required Reason API entry for `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, covering KeepMeter's app-local `@AppStorage` / UserDefaults preferences.

CI:
- lints and structurally validates the source privacy manifest.
- asserts the UserDefaults reason is exactly `CA92.1`.
- builds Release into a deterministic DerivedData path.
- verifies `KeepMeter.app/PrivacyInfo.xcprivacy` exists in the built product and plist-equals the source manifest.

Guardrail:
- revisit privacy manifest and App Store App Privacy answers before release if analytics, crash SDKs, networking/data collection or additional Required Reason APIs are introduced.

## Visual / accessibility / runtime

Implemented:
- polished native visual system across Onboarding, Dashboard, Add Purchase, Purchase Detail, Insights, Archive, Settings and Paywall.
- Dynamic Type adaptive layouts on major screens.
- content-driven button heights where clipping was possible.
- decorative imagery hidden from VoiceOver where appropriate.
- improved accessibility grouping and progress accessibility values.

Gate 15 runtime validation:
- real KeepMeter Debug app installed into a booted iPhone Simulator.
- Light appearance + English onboarding launched and screenshot captured.
- Dark appearance + German dashboard launched and screenshot captured.
- app explicitly terminated and relaunched successfully.
- both screenshots uploaded as GitHub Actions artifact `keepmeter-runtime-screenshots`.
- artifact for workflow `32215165699`: ID `9352256830`, retained 7 days by CI.
- assistant visually inspected both screenshots; no obvious clipping, localization or contrast regression was found in those two covered states.

Important limitation:
- Gate 15 covers two representative runtime states, not a complete visual pass of every screen.

Still open:
- physical-device Light/Dark pass.
- runtime/physical VoiceOver pass.
- physical-device Dynamic Type spot-check.

## V1 brand / AppIcon lock

Public working v1 brand: **KeepMeter**.
Status: **operational v1 brand lock, not legal trademark clearance**.

- no obvious exact same-name consumer app/software result surfaced in searches performed on 2026-08-18.
- search-engine absence is not trademark clearance.
- EUIPO/DPMA/domain/legal clearance is not claimed.
- visual direction lives in `docs/BRAND_DIRECTION.md`.

Locked brand rules:
- primary blue approximately `#306BF5`.
- soft blue approximately `#63A1FF`.
- green reserved for positive/KEEP meaning.
- custom decision-meter/gauge AppIcon with positive KEEP cue.
- no shopping-cart, receipt-vault, bank/crypto, generic AI sparkle, text monogram or red-heavy identity.

Final AppIcon:
- `KeepMeter/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- 1024×1024, opaque/no alpha.
- wired into target Resources.
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in Debug + Release.
- asset compiler passes in Debug + Release.
- presence, metadata, dimensions and opacity are hard CI requirements.

## CI / release preflight

Current required pipeline:
1. StoreKit test configuration validation.
2. App Store Release settings/AppIcon/privacy preflight.
3. EN/DE localization integrity.
4. executable product-rule/DecisionEngine smoke.
5. executable file-backed SwiftData reopen smoke.
6. Debug iOS Simulator build.
7. booted iPhone Simulator install/launch/light-dark/relaunch runtime smoke.
8. runtime screenshot artifact upload.
9. Release iOS Simulator build.
10. built-app privacy-manifest verification.

Workflow concurrency cancels stale runs for the same GitHub ref so old simulator attempts do not accumulate.

`ci/simulator-runtime-smoke.py` uses bounded command timeouts, waits for CoreSimulator boot services, tolerates a delayed `simctl install` client by polling the installed app container, and keeps cleanup best-effort so cleanup cannot mask the actual test failure.

`ci/release-preflight.sh` hard-checks:
- Release configuration.
- bundle ID `de.kamilunavo.keepmeter`.
- version `0.1.0` / positive build `1`.
- generated Info.plist.
- iOS 17.0 deployment target.
- iPhone device family.
- display name `KeepMeter`.
- Utilities category.
- AppIcon build setting/catalog/1024x1024/opacity.
- privacy manifest structure and Required Reason baseline.

A green Simulator pipeline is not a signed Archive and does not replace physical-device/TestFlight validation.

## Verified gates

1. Gate 1 — Functional MVP — PR #1 — workflow `32178808223` — merge `bf024336455d2a65da1e7d5f25ac87f142a3de8d` — GREEN.
2. Gate 2 — Visual polish — PR #2 — workflow `32179763750` — merge `45c53308ae41fc38eec5049c0181d4b0d7ede42b` — GREEN.
3. Gate 3 — StoreKit/reminder hardening — PR #3 — workflow `32182015862` — merge `0ec1e7b87fb3148462fcdc923770684e9bf67f1f` — GREEN.
4. Gate 4 — Notification QA controls — PR #4 — workflow `32182418696` — merge `e82813b2f53677112700c5f0cdbcb0db6a9402c7` — GREEN.
5. Gate 5 — Local StoreKit environment — PR #5 — workflow `32184529919` — merge `f9541c26a4ea63b78c302977a95566827c37b45f` — GREEN.
6. Gate 6 — Data integrity/accessibility — PR #6 — workflow `32185398795` — merge `f3718152acbd7b51ba90bbb399e3de6fc1116d64` — GREEN.
7. Gate 7 — File-backed SwiftData reopen — PR #7 — workflow `32186180485` — merge `2b93368f084ccf4808a0fa2a5e68c5d7dc51bc0c` — GREEN.
8. Gate 8 — Release configuration compile — PR #8 — workflow `32186439191` — merge `dad79a620f375ed2c5eaa9ce4d40784130aab164` — GREEN.
9. Gate 9 — App Store release preflight — PR #9 — workflow `32186964254` — merge `5582461de995c8954f44b78c3314b3dbf2ee22c2` — GREEN.
10. Gate 10 — v1 brand direction lock — PR #10 — workflow `32187367731` — merge `eaadd52c37ce38e98e3ad96a55bda4eaea84291a` — GREEN.
11. Gate 11 — Final AppIcon + hard release asset gate — PR #11 — workflow `32189137123` — merge `cedc90a883713683217f663485a6d8f2e09fd63a` — GREEN.
12. Gate 12 — Production StoreKit entitlement recovery — PR #12 — workflow `32189569075` — merge `56f501c4f220032ba5fb3ab88dd409b94c5524b6` — GREEN.
13. Gate 13 — Product-rule + localization release gates — PR #13 — workflow `32212716880` — merge `fe88224b38011d25934b49a1edb2fc2030425306` — GREEN.
14. Gate 14 — Required-reason privacy manifest + built-bundle verification — PR #14 — workflow `32212975137` — merge `223eb041a0e4f306fd5dc0c5ed29deb7f12cd197` — GREEN.
15. Gate 15 — Booted iOS Simulator runtime + screenshots + terminate/relaunch — PR #15 — workflow `32215165699` — merge `9c5b33bf0a0123afe243a0b32bd4d0139537cd82` — GREEN.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Guardrails / rejected directions

- no account/backend for core v1.
- no bank connection.
- no inbox scraping.
- no generic receipt/warranty-vault positioning.
- no forced subscription.
- no opaque AI recommendation.
- user-entered return dates are informational and not represented as guaranteed legal rights.
- no generic shopping-cart/receipt/bank/AI-sparkle AppIcon direction.

## QA / release status

GREEN / automated:
- functional + visual source builds.
- StoreKit local config/product ID/scheme validation.
- production StoreKit entitlement source hardening.
- localization key/format regression gate.
- product-rule/DecisionEngine regression gate.
- file-backed SwiftData write/reopen verification.
- App Store Release/AppIcon/privacy preflight.
- final AppIcon hard gate and asset compilation.
- privacy manifest built-bundle verification.
- full Debug Simulator compilation.
- booted iPhone Simulator install + Light/EN launch + Dark/DE launch + terminate/relaunch.
- full Release Simulator compilation.

Still not explicitly exercised end-to-end:
- physical-device QA.
- physical force-quit/relaunch with real purchase data.
- real local-notification delivery.
- interactive local StoreKit purchase.
- Free-limit -> Lifetime Pro -> restore.
- complete all-screen Light/Dark runtime review.
- VoiceOver runtime QA.

Release:
- final AppIcon: DONE / CI GREEN.
- privacy manifest: DONE / bundled + CI GREEN.
- production StoreKit source hardening: DONE / CI GREEN.
- no TestFlight build yet.
- no App Store submission yet.
- matching Lifetime IAP still needs App Store Connect configuration.
- signed Archive/export/upload not yet exercised.

## App Store Connect tooling constraint

No App Store Connect / Apple Developer write connector was available in the installed plugin search. Creating the real App Store Connect app/IAP record or uploading through Apple may require an authenticated local Xcode/App Store Connect step rather than repository-only actions.

## Immediate next steps

1. Centralize the v1 free-limit rule so UI and tests cannot drift around a magic number.
2. Expand booted-simulator runtime coverage to a realistic populated dashboard/detail state where useful, without shipping QA behavior in Release.
3. Create/verify the matching Lifetime IAP in App Store Connect: `de.kamilunavo.keepmeter.pro.lifetime`.
4. Exercise interactive local StoreKit Free -> Pro -> restore.
5. Exercise physical-device persistence + real notification delivery.
6. Perform final VoiceOver and broader Light/Dark device inspection.
7. Validate final support/privacy URLs and App Store metadata against the binary.
8. Run first signed Archive and TestFlight upload only after the remaining runtime/Apple gates are green.
