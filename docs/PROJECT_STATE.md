# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — TESTFLIGHT LIFETIME PURCHASE + RESTORE + RELAUNCH VERIFIED / IAP REVIEW SCREENSHOT IN ASC / FINAL ASC METADATA + PHYSICAL QA + LIVE URL GATES OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `968987a52bc675b27451785618a6132fe3eee538`
Current verified release checkpoint: TestFlight workflow run `32294826597` / upload job `96203597997` — SUCCESS
Current physical/TestFlight checkpoint: Gate #26 — user-confirmed on 2026-08-19: build installable, real Lifetime purchase works, IAP review screenshot uploaded in App Store Connect, explicit Restore Purchases works, and Pro entitlement survives/reloads after restart.

## Handoff rule

This file is the authoritative ongoing KeepMeter state.

For future work:
1. Read this file first.
2. Inspect current `main`, open PRs and CI.
3. Continue from `Immediate next steps`.
4. Update this file after every major product/release pass.
5. Never treat workflow-level green as proof if a relevant job is allowed to fail; StoreKit counts only when its required job is actually green.
6. Never claim App Store Connect/TestFlight state beyond the evidence explicitly recorded here.
7. User-confirmed physical/App Store Connect actions must be labeled as user-confirmed unless independently verified through an API/log/source.

## Product thesis

> Is this purchase actually worth keeping before the return window closes?

Core loop: **Bought -> Use -> Measure -> Decide before deadline.**

## Locked v1 product

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
- Free: maximum 5 active purchases.
- Lifetime Pro: unlimited active purchases through one-time StoreKit 2 Non-Consumable.
- No subscription in v1.
- No required account/backend/bank/inbox integration.

## Native target / App Store identity

- SwiftUI + SwiftData + UserNotifications + StoreKit 2.
- iOS 17+; iPhone only.
- Bundle ID `de.kamilunavo.keepmeter`.
- Marketing version `0.1.0`, build `1`.
- App Store name `KeepMeter`.
- Primary language German.
- SKU `keepmeter-ios-001`.
- Category Utilities.
- Base app Free.
- Apple team `TKG684N5GL`.
- Automatic Signing via `Config/Signing.xcconfig`.
- Shared scheme archives Release with `buildForArchiving = YES`.
- First TestFlight lane is intentionally locked to exact release identity `0.1.0 (1)`.

## DecisionEngine + AccessPolicy

DecisionEngine v1:
- deadline passed -> REVIEW.
- 0 uses + <=3 days -> RETURN?.
- <=1 use + <=3 days -> REVIEW.
- 0 uses after >=60% of return window -> REVIEW.
- >=3 uses -> KEEP.
- early window -> REVIEW / gather signal.
- otherwise -> REVIEW / more evidence needed.
- cost/use is informational only; no universal value threshold is claimed.

AccessPolicy v1:
- `AccessPolicy.freeActivePurchaseLimit = 5` is the Free-limit source of truth.
- Free may add while active count <5; sixth active purchase routes to Pro.
- archived/completed purchases do not consume a Free slot.
- Lifetime Pro bypasses the limit.
- `ci/ProductRulesSmoke.swift` directly tests DecisionEngine branches plus Free/Pro boundary behavior.

## Data integrity / persistence

Implemented:
- `Purchase` + `UsageEvent` SwiftData models.
- explicit saves for creation, usage logging and final keep/return actions.
- failed saves roll back and surface localized errors.
- archived items expose no active mutation controls and display stored outcome.
- reminders schedule only after successful save and cancel only after successful archival.

Automated evidence:
- `ci/PersistenceSmoke.swift` writes a real file-backed store, destroys the first container, reopens it and verifies IDs, fields, dates, outcome, usage relationship and cost/use.
- Gate #17 added deterministic running-app SwiftData seed/relaunch verification.
- Later required CI gates repeatedly reran the persistence/runtime path successfully.

Still open:
- optional broader physical purchase-data persistence spot-check beyond the entitlement restart validation already confirmed in Gate #26.

## StoreKit / Lifetime Pro

Locked identity:
- Type: Non-Consumable.
- Reference Name: `KeepMeter Lifetime Pro`.
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Germany launch price: €9.99 one-time.
- No subscription.
- Family Sharing off for v1.

Locked customer metadata:
- DE Display Name: `KeepMeter Pro – Lifetime`.
- DE Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`
- EN Display Name: `KeepMeter Pro Lifetime`.
- EN Description: `Unlimited active purchases. Pay once.`

Implemented/hardened:
- local `.storekit` NonConsumable test product.
- required metadata preflight.
- `Transaction.currentEntitlements`, verified `Transaction.updates` and `Transaction.unfinished` handled.
- access refresh occurs before `transaction.finish()`.
- unverified transactions never unlock Pro.
- `AppStore.sync()` only behind explicit Restore Purchases.
- Gate #21 required StoreKitTest/XCTest proves Free -> Lifetime transaction -> Pro unlock -> entitlement recovery in a recreated `EntitlementStore` -> entitlement removal after clearing StoreKitTest state.
- StoreKit job is required CI.

Apple/TestFlight state confirmed by user on 2026-08-19:
- KeepMeter App Store Connect app record exists with the locked identity.
- Lifetime Pro IAP exists as Non-Consumable with the locked Product ID.
- Germany price/availability is €9.99.
- DE/EN IAP localizations and Review Notes are entered.
- repository ASC secrets are provisioned and were validated by Gate #24 upload.
- TestFlight build `0.1.0 (1)` completed processing and is installable.
- real Apple/TestFlight Lifetime Pro offer loads on the physical iPhone.
- real Lifetime Pro purchase succeeds.
- real Pro/paywall screenshot was captured and is uploaded in the Lifetime IAP App Review Screenshot field in App Store Connect.
- explicit Restore Purchases succeeds and restores Pro.
- post-purchase restart/relaunch correctly preserves or reloads the Lifetime Pro entitlement.

This closes the real purchase/restore/relaunch StoreKit release path for build `0.1.0 (1)`.

## App Store listing / privacy / App Store Connect handoff

Repository sources of truth:
- `metadata/AppStoreListing.json`
- `metadata/AppStoreConnectSetup.json`
- `docs/APP_STORE_CONNECT_RUNBOOK.md`
- `docs/APP_STORE_RELEASE.md`
- `docs/IAP_LIFETIME_PRO.md`
- `docs/APP_PRIVACY_HANDOFF.md`

Required CI cross-checks:
- exact app-record platform/name/primary language/bundle/SKU/category/base-price/version/build.
- DE/EN listing field limits and locale set.
- exact Lifetime Pro product identity, launch-price decision and localizations.
- guarded TestFlight workflow path/main/confirmation/build-number-management.
- Privacy baseline: Data Not Collected / Tracking No, subject to mandatory final-binary re-audit.

Still requiring explicit final App Store Connect review before submission:
- final App Store listing fields and screenshots/metadata as applicable.
- final App Privacy answers.
- EU DSA trader-status/account/app setting; repository state is not a legal determination.

## Privacy

`KeepMeter/PrivacyInfo.xcprivacy` is bundled and CI-gated.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- UserDefaults Required Reason `CA92.1`.
- Release bundle manifest must plist-match source.

Re-audit if analytics, crash SDKs, networking/data collection, push-token handling or other off-device behavior is added.

## Notifications / accessibility / visual

Implemented:
- local reminders around entered return date.
- stable DE/EN dynamic format localization.
- Settings exposes authorization state, request action and iOS Settings handoff.
- Dynamic Type adaptive layouts on major screens.
- VoiceOver grouping/hiding applied where appropriate in source.
- `ci/localization-preflight.py` enforces EN/DE key parity, no duplicates/empties and matching format placeholders.
- native `ci/RuntimeScreenshotSignal.swift` rejects black/near-uniform screenshots.

Physical/TestFlight evidence:
- Gate #25 reached the real TestFlight paywall and completed a real Lifetime purchase.
- Gate #26 confirmed IAP review screenshot upload, explicit Restore Purchases and entitlement recovery after restart.

Still open:
- real scheduled-notification delivery on physical device/TestFlight build.
- broader representative Light/Dark physical review.
- physical VoiceOver pass.
- physical Dynamic Type spot-check.

## Website / public release pages

Kamilunavo source merges:
- `afd809da2f814625b1cf45f6920c958897fb5398` added KeepMeter privacy page source and KeepMeter support presence.
- `6cf96be83b29e74ad5414cc02e4997d3508e6f57` hardened `/support` with direct support/business contact information and imprint link.

Intended App Store URLs:
- `https://kamilunavo.com/keepmeter/privacy`
- `https://kamilunavo.com/support`

User confirmed the Kamilunavo production deploy was executed on 2026-08-19. Independent external live verification from this session remains unresolved; do not mark the URLs live-verified until independently confirmed.

## Signing / Archive / TestFlight

Gate #24 first real TestFlight upload — connector/log VERIFIED:
- Workflow: `KeepMeter TestFlight`.
- Run: `32294826597`.
- Job: `96203597997` (`upload`).
- exact confirmation and `main` guard passed.
- Xcode 26.2 selected.
- StoreKit/listing/localization/release preflights passed.
- all three KeepMeter ASC secrets present; private key decoded successfully.
- signed Release archive: `** ARCHIVE SUCCEEDED **`.
- code-sign verification passed.
- verified identity: `de.kamilunavo.keepmeter 0.1.0 (1)`.
- verified TeamIdentifier: `TKG684N5GL`.
- App Store Connect upload analysis completed without rejection.
- Apple log: `Uploaded package is processing.`
- Apple log: `Upload succeeded.` / `Uploaded KeepMeter`.
- export: `** EXPORT SUCCEEDED **`.
- temporary API private key cleanup succeeded.

Gate #25 physical/TestFlight purchase — USER-CONFIRMED:
- Apple processing completed sufficiently for TestFlight distribution.
- build `0.1.0 (1)` is visible/installable on a physical iPhone.
- real Lifetime Pro offer loads from Apple/TestFlight.
- real Lifetime purchase succeeds.
- real IAP review screenshot was captured from the TestFlight/release-candidate paywall.

Gate #26 StoreKit recovery + IAP review evidence — USER-CONFIRMED:
- captured real paywall screenshot is uploaded in App Store Connect as the Lifetime IAP App Review Screenshot.
- explicit Restore Purchases path succeeds on the TestFlight build.
- restarting/relaunching after purchase correctly retains or reloads the Lifetime Pro entitlement.

## Verified gates

1–16 — MVP/product rules/visual polish/StoreKit-reminder hardening/data integrity/accessibility/persistence/release compile/App Store preflight/brand/AppIcon/privacy/runtime/access policy — GREEN and merged.
17. PR #17 — populated Simulator persistence + active-scene + screenshot signal + Release QA isolation — workflow `32249500834` — GREEN.
18. PR #19 — arm64 runtime infrastructure + bounded pre-install fallback — workflow `32257672022` — GREEN.
19. PR #18 — App Store/IAP/listing/privacy handoff — workflow `32258911074` — GREEN.
20. PR #20 — signing/archive preflight + same-device simulator lifecycle hardening — workflow `32276400054` — GREEN.
21. PR #24 + #25 — real iOS Simulator StoreKitTest Lifetime entitlement proof promoted to required CI — final required workflow `32284909516` — GREEN.
22. PR #27 — guarded manual signed Archive/TestFlight lane + required workflow-safety preflight — workflow `32287632445` — GREEN.
23. PR #29 — exact ASC machine-readable setup + immutable SKU + Apple-side runbook + required handoff preflight — workflow `32290236121` — GREEN.
24. Manual TestFlight workflow run `32294826597`, job `96203597997` — signed exact KeepMeter `0.1.0 (1)`, Apple accepted upload, `Upload succeeded`, `EXPORT SUCCEEDED` — GREEN. Gate #24 docs PR #31 reran required StoreKit + full normal runtime/Release/Privacy CI and merged as `7e9f02a5a09fc9d59a4b2d266346810b69d62ba6`.
25. Physical/TestFlight validation — user-confirmed 2026-08-19: processed/installable build, real Lifetime offer, successful real purchase, real paywall screenshot captured. Gate #25 docs PR #32 reran required StoreKit + full normal runtime/Release/Privacy CI and merged as `e7a85015ba74500880b4a448b744ee243b279d22`.
26. Physical/TestFlight recovery + ASC IAP screenshot — user-confirmed 2026-08-19: App Review Screenshot uploaded in ASC, explicit Restore Purchases succeeds, and Lifetime entitlement survives/reloads after restart. Gate #26 documentation must pass required CI before merge.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Release status

DONE / verified or explicitly user-confirmed:
- functional Debug + Release builds.
- AppIcon and Privacy Manifest.
- DecisionEngine / AccessPolicy / EN-DE regression tests.
- file-backed and running-app SwiftData persistence evidence.
- representative runtime visual evidence + anti-black-screen gate.
- DEBUG QA isolation from Release binary.
- required arm64 CI + required StoreKit entitlement XCTest.
- exact Lifetime Pro identity/copy/price handoff.
- App Store Connect app record created.
- Lifetime Pro IAP setup, price, availability, DE/EN localizations and Review Notes entered.
- KeepMeter ASC repository secrets provisioned and validated by Gate #24.
- signed Release Archive for exact `0.1.0 (1)` created and verified.
- first real App Store Connect/TestFlight upload accepted by Apple.
- TestFlight build processed/installable on physical iPhone.
- real Lifetime purchase works.
- real IAP App Review Screenshot uploaded in ASC.
- explicit Restore Purchases works.
- Lifetime entitlement persists/reloads after restart.

OPEN / external or device-only:
- remaining physical QA: scheduled reminder delivery, VoiceOver, Dynamic Type and representative Light/Dark review.
- independent live verification of KeepMeter privacy/support URLs.
- final App Store listing entry/review in ASC.
- final App Privacy entry/review in ASC.
- EU DSA trader-status/account/app verification.
- final App Store submission readiness.

## Immediate next steps

1. Perform the remaining physical-device QA: scheduled reminder delivery, VoiceOver, Dynamic Type and representative Light/Dark screens.
2. Independently verify `https://kamilunavo.com/keepmeter/privacy` and `https://kamilunavo.com/support` publicly.
3. Finish/review the App Store listing and screenshots/metadata in App Store Connect.
4. Enter/review final App Privacy answers in App Store Connect.
5. Verify EU DSA trader-status/account/app setting without inferring a legal conclusion from repository state.
6. When those gates are green, prepare the final App Store submission.