# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — TESTFLIGHT BUILD INSTALLABLE + REAL LIFETIME PURCHASE VERIFIED / IAP REVIEW SCREENSHOT CAPTURED / RESTORE + SCREENSHOT UPLOAD + FINAL ASC METADATA + PHYSICAL QA GATES OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `968987a52bc675b27451785618a6132fe3eee538`
Current verified release checkpoint: TestFlight workflow run `32294826597` / upload job `96203597997` — SUCCESS
Current physical/TestFlight checkpoint: Gate #25 — user-confirmed on 2026-08-19: build processed/installable, Lifetime Pro purchase works, review screenshot captured locally.

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
- Gates #18/#20/#21/#22/#23/#24-doc-CI reran the persistence/runtime path successfully after later release hardening.

Still open:
- equivalent force-quit/relaunch persistence spot-check on the physical TestFlight build.

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
- shared Debug scheme references local StoreKit config.
- required `ci/storekit-metadata-preflight.py` checks exact product identity/copy and field limits.
- `Transaction.currentEntitlements`, verified `Transaction.updates` and `Transaction.unfinished` handled.
- access refresh occurs before `transaction.finish()`.
- unverified transactions never unlock Pro.
- `AppStore.sync()` exists only behind explicit Restore Purchases.
- Gate #21 required StoreKitTest/XCTest proves Free -> Lifetime transaction -> Pro unlock -> entitlement recovery in a recreated `EntitlementStore` -> entitlement removal after clearing StoreKitTest state.
- StoreKit job is required CI; `continue-on-error` was removed in Gate #21.

Apple-side state confirmed by user on 2026-08-19:
- KeepMeter App Store Connect app record created with the locked identity.
- Lifetime Pro IAP created as Non-Consumable with the locked Product ID.
- Germany price/availability configured at €9.99.
- DE/EN IAP localizations entered.
- IAP Review Notes entered.
- Repository ASC secrets provisioned: `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY_B64`.
- TestFlight build `0.1.0 (1)` completed Apple processing and became visible/installable.
- real Apple/TestFlight Lifetime Pro offer loads on the physical iPhone.
- real Lifetime Pro purchase completes successfully (`kauf klappt`, user-confirmed).
- real Pro/paywall screenshot was captured locally for IAP review.

Still open / not overclaimed:
- upload the captured paywall screenshot into the Lifetime IAP App Review Screenshot field unless already done and explicitly confirmed.
- explicit Restore Purchases (`AppStore.sync()`) validation on a clean/reinstalled appropriate test state.
- explicit post-purchase force-quit/relaunch entitlement-persistence confirmation on the physical TestFlight build.

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

Apple/account items still requiring explicit verification before App Store submission:
- EU DSA trader-status/account/app setting; repository state must not be treated as a legal determination.
- final App Store listing metadata entry/review in ASC.
- final App Privacy answers in ASC.
- IAP review screenshot upload if not already completed.

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
- Gate #25 confirms the real TestFlight Pro/paywall was reached and a review screenshot was captured locally.

Still open:
- real scheduled-notification delivery on physical device/TestFlight build.
- broader physical Light/Dark review.
- physical VoiceOver pass.
- physical Dynamic Type spot-check.

## Website / public release pages

Kamilunavo source merges:
- `afd809da2f814625b1cf45f6920c958897fb5398` added KeepMeter privacy page source and KeepMeter support presence.
- `6cf96be83b29e74ad5414cc02e4997d3508e6f57` hardened `/support` with direct support/business contact information and imprint link.

Intended App Store URLs:
- `https://kamilunavo.com/keepmeter/privacy`
- `https://kamilunavo.com/support`

User confirmed the Kamilunavo production deploy was executed on 2026-08-19. Independent external live verification from this session remains unresolved because the external resolver could not reliably resolve `kamilunavo.com`; do not mark the URLs live-verified until independently confirmed.

## Signing / Archive / TestFlight

Known team: `TKG684N5GL`.

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

Gate #25 physical/TestFlight validation — USER-CONFIRMED:
- Apple processing completed sufficiently for TestFlight distribution.
- build `0.1.0 (1)` is visible/installable on a physical iPhone.
- real Lifetime Pro offer loads from Apple/TestFlight.
- real Lifetime purchase succeeds.
- IAP review screenshot was captured locally from the real TestFlight/release-candidate paywall.
- this gate does not by itself prove explicit Restore Purchases or post-purchase relaunch recovery; those remain separate checks until explicitly confirmed.

## Verified gates

1–16 — MVP/product rules/visual polish/StoreKit-reminder hardening/data integrity/accessibility/persistence/release compile/App Store preflight/brand/AppIcon/privacy/runtime/access policy — GREEN and merged.

17. PR #17 — populated Simulator persistence + active-scene + screenshot signal + Release QA isolation — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6` — GREEN.
18. PR #19 — arm64 runtime infrastructure + bounded pre-install fallback — workflow `32257672022` — merge `1e819921a977614c6364f31f4abab0170ed9ef1b` — GREEN.
19. PR #18 — App Store/IAP/listing/privacy handoff — workflow `32258911074` — merge `85160a6e66774bdbd1128fa066abc5bd66371d52` — GREEN.
20. PR #20 — signing/archive preflight + same-device simulator lifecycle hardening — workflow `32276400054` — merge `4d63db7d32ec24ffd4beb59e506369e2c25ba2c1` — GREEN.
21. PR #24 + #25 — real iOS Simulator StoreKitTest Lifetime entitlement proof promoted to required CI — final required workflow `32284909516` — merge `222464d21c888fdae5d01b07b6569a76ca2749a7` — GREEN.
22. PR #27 — guarded manual signed Archive/TestFlight lane + required workflow-safety preflight — workflow `32287632445` — merge `8828fc2f706d2dec44ea48536d4928026aaa9d75` — GREEN.
23. PR #29 — exact ASC machine-readable setup + immutable SKU + Apple-side runbook + required handoff preflight — workflow `32290236121` — merge `968987a52bc675b27451785618a6132fe3eee538` — GREEN.
24. Manual TestFlight workflow run `32294826597`, job `96203597997` — signed exact KeepMeter `0.1.0 (1)`, Apple accepted upload, `Upload succeeded`, `EXPORT SUCCEEDED` — GREEN. Gate #24 docs PR #31 subsequently reran required StoreKit + full normal runtime/Release/Privacy CI successfully and merged to `main` as `7e9f02a5a09fc9d59a4b2d266346810b69d62ba6`.
25. Physical/TestFlight validation — user-confirmed 2026-08-19: processed/installable TestFlight build, real Lifetime Pro offer, successful real purchase, real paywall screenshot captured locally. Restore/relaunch recovery are not included in this gate unless separately confirmed.

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
- App Store Connect app record created (user-confirmed).
- Lifetime Pro IAP core setup, price, availability, DE/EN localizations and Review Notes entered (user-confirmed).
- KeepMeter ASC repository secrets provisioned and validated by successful Gate #24 workflow.
- signed Release Archive for exact `0.1.0 (1)` created and verified.
- first real App Store Connect/TestFlight upload accepted by Apple.
- Apple processing completed sufficiently for build installation (user-confirmed).
- real physical TestFlight Lifetime purchase works (user-confirmed).
- real IAP/paywall review screenshot captured locally (user-confirmed).

OPEN / external or device-only:
- upload/confirm the captured IAP App Review Screenshot in App Store Connect.
- explicit Restore Purchases validation.
- explicit physical post-purchase relaunch entitlement persistence.
- physical-device persistence/notification/VoiceOver/Dynamic Type/Light-Dark checks not already covered above.
- independent live verification of KeepMeter privacy/support URLs.
- final App Store listing and App Privacy entry/review in ASC.
- EU DSA trader-status/account/app verification.
- final App Store submission readiness.

## Immediate next steps

1. Upload the captured real TestFlight paywall screenshot to the Lifetime IAP **App Review Screenshot** field and save it.
2. Validate explicit **Restore Purchases** on an appropriate clean/reinstalled test state; confirm Pro returns through the user-triggered restore path.
3. Force-quit/relaunch the physical TestFlight build after purchase and confirm Lifetime Pro entitlement persists/reloads correctly.
4. Perform remaining physical-device checks: scheduled reminder delivery, VoiceOver, Dynamic Type, and representative Light/Dark screens.
5. Independently verify `https://kamilunavo.com/keepmeter/privacy` and `https://kamilunavo.com/support` publicly.
6. Finish/review App Store listing, App Privacy and EU DSA/account settings in App Store Connect.
7. Only after the above gates are green, prepare the final App Store submission.