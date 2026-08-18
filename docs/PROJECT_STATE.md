# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — FINAL APPICON + RELEASE ASSET GATE GREEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified checkpoint: `cedc90a883713683217f663485a6d8f2e09fd63a`

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

## Native stack / target

- SwiftUI
- SwiftData
- UserNotifications
- StoreKit 2
- iOS 17+
- iPhone target
- Bundle ID: `de.kamilunavo.keepmeter`
- Marketing version: `0.1.0`
- Build: `1`
- App category: Utilities
- Generated Info.plist
- GitHub Actions validates StoreKit, App Store release settings/assets, persistence, Debug and Release simulator builds.

## Data integrity / persistence

Implemented:

- `Purchase` + `UsageEvent` SwiftData models.
- Active / kept / returned outcomes.
- Archived purchases are read-only in detail view and expose no active mutation controls.
- Archived purchases show stored final outcome rather than a newly recalculated live recommendation.
- Active-state guards protect purchase mutations.
- Purchase creation, usage logging and final keep/return actions use explicit save handling.
- Failed saves roll back and show localized errors instead of silently succeeding.
- Return reminders are scheduled only after successful purchase persistence.
- Existing reminders are cancelled only after the final archived state successfully persists.
- `ci/PersistenceSmoke.swift` writes the real models to a file-backed store, destroys the container, reopens the same store and verifies IDs, fields, dates, outcome, usage relationship and derived cost per use.

Validated:

- executable file-backed write -> reopen persistence gate is green.

Not yet claimed:

- physical iPhone force-quit -> relaunch persistence session.

## StoreKit / monetization

- Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Free limit: 5 active purchases; completed purchases do not count.
- Lifetime Pro unlocks unlimited active purchases.
- Local StoreKit configuration: `KeepMeter/StoreKit/KeepMeter.storekit`.
- Local product type: NonConsumable.
- Local test price: 9.99; this does not lock the final App Store price.
- DE/EN local product metadata exists.
- Shared Debug scheme references the local StoreKit configuration.
- CI validates StoreKit JSON, exact product ID and scheme reference.
- DEBUG-only Settings diagnostics expose product ID, loaded state, test price, entitlement and reload/refresh controls.
- Missing-product / first-tap purchase loading behavior is hardened.

Not yet claimed:

- interactive local StoreKit Free -> Pro -> restore run.
- App Store Connect Lifetime IAP creation.
- sandbox/TestFlight purchase/restore run.

## Notifications

Implemented:

- local reminders around the entered return deadline.
- stable DE/EN format localization for dynamic reminder copy.
- Settings reads current `UNAuthorizationStatus`.
- permission can be requested from Settings.
- denied state offers iOS Settings handoff.
- notification status refreshes when the app becomes active again.

Not yet claimed:

- actual delivery of a scheduled notification on a physical device.

## Visual / accessibility system

Implemented:

- polished native visual system across Onboarding, Dashboard, Add Purchase, Purchase Detail, Insights, Archive, Settings and Paywall.
- adaptive app background and material cards.
- blue KeepMeter primary accent with semantic green/orange/red decision states.
- return-window progress treatment.
- strong metric hierarchy and decision hero treatment.
- accessibility-size adaptive layouts on major screens.
- content-driven button heights where fixed heights could clip.
- decorative imagery hidden from VoiceOver where appropriate.
- key cards/metrics use improved accessibility grouping.
- return-window progress exposes an accessibility value.

Not yet claimed:

- complete runtime Light/Dark visual inspection.
- physical/runtime VoiceOver pass.

## V1 brand / AppIcon lock

Public working brand for production design/App Store preparation: **KeepMeter**.

Status: **operational v1 brand lock, not legal trademark clearance**.

- no obvious exact same-name consumer app/software result surfaced in searches performed on 2026-08-18.
- search-engine absence is not trademark clearance.
- EUIPO/DPMA/domain/legal clearance is not claimed.
- locked visual direction lives in `docs/BRAND_DIRECTION.md`.

Locked palette/direction:

- primary blue approximately `#306BF5`.
- soft blue approximately `#63A1FF`.
- green reserved for positive/KEEP meaning.
- final AppIcon uses the custom decision-meter/gauge direction with positive KEEP cue.
- no shopping-cart, receipt-vault, bank/crypto, generic AI sparkle or red-heavy identity.
- no text or `K` monogram in the primary icon.

Final release asset:

- `KeepMeter/Assets.xcassets/AppIcon.appiconset/AppIcon.png` exists.
- source image is 1024×1024 and opaque/no alpha.
- `Assets.xcassets` is wired into the target Resources phase.
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` is set for Debug and Release.
- Xcode asset compilation succeeds in both Debug and Release simulator builds.
- AppIcon presence, metadata, exact dimensions and opacity are now hard CI requirements.

## Release / App Store preflight

`ci/release-preflight.sh` reads Xcode Release build settings as source of truth and hard-checks:

- Release configuration.
- bundle ID `de.kamilunavo.keepmeter`.
- marketing version `0.1.0`.
- positive build number `1`.
- generated Info.plist.
- iOS 17.0 deployment target.
- iPhone device family.
- display name `KeepMeter`.
- Utilities category.
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
- final asset catalog and AppIcon metadata.
- AppIcon PNG 1024×1024 dimensions.
- AppIcon no-alpha/opaque requirement.

`docs/APP_STORE_RELEASE.md` contains the App Store Connect checklist, DE/EN listing drafts, privacy constraints, screenshot plan and runtime submission checklist.

A simulator Release build is not a signed Archive and does not replace TestFlight validation.

## Verified gates

1. Gate 1 — Functional MVP — PR #1 — workflow `32178808223` — merge `bf024336455d2a65da1e7d5f25ac87f142a3de8d` — GREEN.
2. Gate 2 — Visual polish — PR #2 — workflow `32179763750` — merge `45c53308ae41fc38eec5049c0181d4b0d7ede42b` — GREEN.
3. Gate 3 — StoreKit/reminder hardening — PR #3 — workflow `32182015862` — merge `0ec1e7b87fb3148462fcdc923770684e9bf67f1f` — GREEN.
4. Gate 4 — Notification QA controls — PR #4 — workflow `32182418696` — merge `e82813b2f53677112700c5f0cdbcb0db6a9402c7` — GREEN.
5. Gate 5 — Local StoreKit environment — PR #5 — workflow `32184529919` — merge `f9541c26a4ea63b78c302977a95566827c37b45f` — GREEN.
6. Gate 6 — Data integrity/accessibility hardening — PR #6 — workflow `32185398795` — merge `f3718152acbd7b51ba90bbb399e3de6fc1116d64` — GREEN.
7. Gate 7 — File-backed SwiftData reopen — PR #7 — workflow `32186180485` — merge `2b93368f084ccf4808a0fa2a5e68c5d7dc51bc0c` — GREEN.
8. Gate 8 — Release configuration compile — PR #8 — workflow `32186439191` — merge `dad79a620f375ed2c5eaa9ce4d40784130aab164` — GREEN.
9. Gate 9 — App Store release preflight — PR #9 — workflow `32186964254` — merge `5582461de995c8954f44b78c3314b3dbf2ee22c2` — GREEN.
10. Gate 10 — v1 brand direction lock — PR #10 — workflow `32187367731` — merge `eaadd52c37ce38e98e3ad96a55bda4eaea84291a` — GREEN.
11. Gate 11 — Final AppIcon + hard release asset gate — PR #11 — workflow `32189137123` — merge `cedc90a883713683217f663485a6d8f2e09fd63a` — StoreKit / release preflight / SwiftData reopen / Debug / Release all GREEN.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## DecisionEngine v1

- deadline passed -> REVIEW.
- zero uses and <= 3 days remaining -> RETURN?.
- <= 1 use and <= 3 days remaining -> REVIEW.
- zero uses after >= 60% of return window -> REVIEW.
- >= 3 logged uses -> KEEP signal.
- early window -> REVIEW / collect more signal.
- otherwise -> REVIEW / more evidence needed.

Cost per use is informative only; there is no pretend universal monetary threshold for personal value.

## Guardrails / rejected directions

- no account/backend for core v1.
- no bank connection.
- no inbox scraping.
- no generic receipt/warranty-vault positioning.
- no forced subscription.
- no opaque AI recommendation.
- user-entered return dates are informational and are not represented as guaranteed legal rights.
- no generic shopping-cart/receipt/bank/AI-sparkle AppIcon direction.

## QA / release status

GREEN / structurally validated:

- functional simulator compile.
- visual-polish compile.
- StoreKit/reminder hardening compile.
- notification-controls compile.
- local StoreKit config/product ID/scheme validation.
- data-integrity + Dynamic Type/accessibility source hardening compile.
- file-backed SwiftData write/reopen verification.
- mutation save rollback behavior in source paths.
- App Store-facing Release build-setting preflight.
- final AppIcon asset presence/metadata/dimensions/opacity hard gate.
- final AppIcon successfully compiled by Xcode asset compiler in Debug and Release.
- full Debug simulator compilation.
- full Release simulator compilation.
- v1 visual/brand direction documented and CI-gated.

Still not explicitly exercised end-to-end:

- physical-device QA.
- physical terminate/relaunch persistence behavior.
- actual local-notification delivery on device.
- interactive local StoreKit purchase session.
- Free-limit -> Lifetime Pro -> restore flow.
- runtime light/dark inspection.
- runtime VoiceOver QA.

Release:

- final AppIcon: DONE / CI GREEN.
- no TestFlight build yet.
- no App Store submission yet.
- matching Lifetime IAP still needs App Store Connect configuration.
- signed Archive/export/upload has not yet been exercised.

## App Store Connect tooling constraint

No App Store Connect / Apple Developer write connector was available in the installed plugin search on 2026-08-18. Creating the actual App Store Connect app/IAP record or uploading through Apple may therefore require an authenticated local Xcode/App Store Connect step rather than a repository-only action.

## Immediate next steps

1. Configure the matching Lifetime IAP in App Store Connect: `de.kamilunavo.keepmeter.pro.lifetime`.
2. Exercise interactive local StoreKit Free -> Pro -> restore.
3. Exercise physical-device persistence and notification delivery.
4. Perform final runtime light/dark + VoiceOver inspection.
5. Validate support/privacy URLs and final App Store metadata against the actual v1 binary.
6. Run the first signed Archive and TestFlight upload only after the runtime gates are green.
