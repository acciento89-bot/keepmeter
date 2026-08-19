# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — FIRST TESTFLIGHT UPLOAD ACCEPTED BY APP STORE CONNECT / APPLE PROCESSING + TESTFLIGHT DEVICE VALIDATION + IAP REVIEW SCREENSHOT + FINAL ASC METADATA GATES OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `968987a52bc675b27451785618a6132fe3eee538`
Current verified release checkpoint: TestFlight workflow run `32294826597` / upload job `96203597997` — SUCCESS

## Handoff rule

This file is the authoritative ongoing KeepMeter state.

For future work:
1. Read this file first.
2. Inspect current `main`, open PRs and CI.
3. Continue from `Immediate next steps`.
4. Update this file after every major product/release pass.
5. Never treat workflow-level green as proof if a relevant job is allowed to fail; StoreKit counts only when its required job is actually green.
6. Never claim App Store Connect/TestFlight state beyond the evidence explicitly recorded here.

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
- Gates #18/#20/#21/#22/#23 reran the persistence/runtime path successfully after later release hardening.

Still open:
- equivalent force-quit/relaunch check on a physical iPhone/TestFlight build.

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
- DEBUG Settings diagnostics for product/price/entitlement.
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

Still open:
- Apple IAP review screenshot from the real TestFlight/release-candidate paywall.
- real sandbox/TestFlight Lifetime purchase + entitlement persistence + explicit Restore Purchases validation.

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
- current agreements/account state if not already satisfied by the successful upload.
- EU DSA trader-status/account/app setting; repository state must not be treated as a legal determination.
- final App Store listing metadata entry/review in ASC.
- final App Privacy answers in ASC.

## Privacy

`KeepMeter/PrivacyInfo.xcprivacy` is bundled and CI-gated.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- UserDefaults Required Reason `CA92.1`.
- Release bundle manifest must plist-match source.

Re-audit if analytics, crash SDKs, networking/data collection, push-token handling or other off-device behavior is added.

## Notifications

Implemented:
- local reminders around entered return date.
- stable DE/EN dynamic format localization.
- Settings exposes authorization state, request action and iOS Settings handoff.
- authorization state refreshes when app becomes active.

Still open:
- real scheduled-notification delivery on physical device/TestFlight build.

## Localization / accessibility / visual

- polished native UI across Onboarding, Dashboard, Add, Detail, Insights, Archive, Settings and Paywall.
- Dynamic Type adaptive layouts on major screens.
- VoiceOver grouping/hiding applied where appropriate in source.
- `ci/localization-preflight.py` enforces EN/DE key parity, no duplicates/empties and matching format placeholders.
- native `ci/RuntimeScreenshotSignal.swift` rejects black/near-uniform screenshots.

Latest required-CI runtime evidence before Gate #24:
- Gate #23 workflow `32290236121`.
- artifact `9379371189` (`keepmeter-runtime-screenshots`).
- screenshot generation and native visual-signal validation passed.
- latest manually inspected representative runtime artifact remains Gate #20 `9374353233`, clean for fresh EN/Light onboarding, populated EN/Light dashboard and persisted DE/Dark dashboard.

Still open:
- real TestFlight paywall screenshot for IAP review.
- broader physical-device Light/Dark review.
- physical/runtime VoiceOver pass.
- physical Dynamic Type spot-check.

## Runtime CI hardening

Required runner: **`macos-26` Apple Silicon / arm64**.

Gate #17:
- DEBUG-only deterministic purchase seeding and persistence sentinel.
- unique per-launch active-scene token.
- bounded foreground nudge.
- visual-signal validation for screenshots.
- Release binary scan rejects DEBUG-only runtime markers/data.

Gate #19:
- moved required CI to `macos-26` arm64.
- at most two iPhone simulator setup attempts before installation.
- no alternate-device retry after KeepMeter installs.

Gate #20:
- hardened screenshot and same-device CoreSimulator recovery without weakening active-scene/persistence assertions.

Gate #21:
- separate required StoreKit entitlement XCTest lane pinned to Xcode 26.2 / iOS 26.2.

Gate #22:
- guarded manual `.github/workflows/testflight.yml`.
- `workflow_dispatch` only; no automatic triggers.
- main branch only.
- exact confirmation `UPLOAD_KEEP_METER_0_1_0_BUILD_1`.
- exact bundle/version/build checks.
- App Store Connect export uses `destination=upload`, Automatic Signing, team `TKG684N5GL`, and `manageAppVersionAndBuildNumber=false`.

Gate #23:
- exact machine-readable ASC setup and operational runbook.
- required `ci/app-store-connect-handoff-preflight.py`.
- DSA and live-URL status deliberately remain explicit external verification items rather than guessed conclusions.

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

Gate #24 first real TestFlight upload — VERIFIED:
- Workflow: `KeepMeter TestFlight`.
- Run: `32294826597`.
- Job: `96203597997` (`upload`).
- Checkout/main guard: success.
- Exact confirmation `UPLOAD_KEEP_METER_0_1_0_BUILD_1`: success.
- Xcode 26.2 selected.
- StoreKit/listing/localization/release preflights: success.
- All three KeepMeter ASC secrets present and the private key decoded successfully.
- Signed Release archive: `** ARCHIVE SUCCEEDED **`.
- Archive code-sign verification: valid on disk / satisfies Designated Requirement.
- Verified identity: `de.kamilunavo.keepmeter 0.1.0 (1)`.
- Verified TeamIdentifier: `TKG684N5GL`.
- Export options: `app-store-connect`, `destination=upload`, Automatic Signing, `manageAppVersionAndBuildNumber=false`.
- App Store Connect upload analysis completed without rejection.
- Apple upload log reached 100% and reported: `Uploaded package is processing.`
- Apple upload log then reported: `Upload succeeded.` and `Uploaded KeepMeter`.
- Export finished with `** EXPORT SUCCEEDED **`.
- Temporary API private key cleanup step succeeded.

Boundary after Gate #24:
- The package is accepted by App Store Connect and processing has begun.
- This is proof of successful upload, not yet proof that Apple processing is complete, the build is visible/installable in TestFlight, or the IAP works against Apple sandbox/TestFlight.

## Verified gates

1–16 — MVP/product rules/visual polish/StoreKit-reminder hardening/data integrity/accessibility/persistence/release compile/App Store preflight/brand/AppIcon/privacy/runtime/access policy — GREEN and merged.

17. PR #17 — populated Simulator persistence + active-scene + screenshot signal + Release QA isolation — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6` — GREEN.
18. PR #19 — arm64 runtime infrastructure + bounded pre-install fallback — workflow `32257672022` — merge `1e819921a977614c6364f31f4abab0170ed9ef1b` — GREEN.
19. PR #18 — App Store/IAP/listing/privacy handoff — workflow `32258911074` — merge `85160a6e66774bdbd1128fa066abc5bd66371d52` — GREEN.
20. PR #20 — signing/archive preflight + same-device simulator lifecycle hardening — workflow `32276400054` — merge `4d63db7d32ec24ffd4beb59e506369e2c25ba2c1` — GREEN.
21. PR #24 + #25 — real iOS Simulator StoreKitTest Lifetime entitlement proof promoted to required CI — final required workflow `32284909516` — merge `222464d21c888fdae5d01b07b6569a76ca2749a7` — GREEN.
22. PR #27 — guarded manual signed Archive/TestFlight lane + required workflow-safety preflight — workflow `32287632445` — merge `8828fc2f706d2dec44ea48536d4928026aaa9d75` — GREEN.
23. PR #29 — exact ASC machine-readable setup + immutable SKU + Apple-side runbook + required handoff preflight — workflow `32290236121` — merge `968987a52bc675b27451785618a6132fe3eee538` — GREEN.
24. Manual TestFlight workflow run `32294826597`, job `96203597997` — signed exact KeepMeter `0.1.0 (1)`, Apple accepted upload, package entered processing, `Upload succeeded`, `EXPORT SUCCEEDED` — GREEN. Processing/TestFlight installability remains the next Apple-side boundary.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Release status

DONE / verified:
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
- KeepMeter ASC repository secrets provisioned (user-confirmed; validated by successful Gate #24 workflow).
- signed Release Archive for exact `0.1.0 (1)` successfully created and verified.
- first real App Store Connect/TestFlight upload accepted by Apple; package entered processing.

OPEN / external or device-only:
- independent live verification of KeepMeter privacy/support URLs.
- Apple processing completion and TestFlight build visibility/installability.
- IAP App Review screenshot from the real TestFlight/release-candidate paywall.
- real sandbox/TestFlight Lifetime purchase + entitlement persistence + explicit Restore Purchases.
- physical-device persistence/notification/VoiceOver/Dynamic Type checks.
- final App Store listing and App Privacy entry/review in ASC.
- EU DSA trader-status/account/app verification.
- final App Store submission readiness.

## Immediate next steps

1. Confirm App Store Connect finishes processing KeepMeter `0.1.0 (1)` and the build becomes visible/installable in TestFlight.
2. Install the TestFlight build on a physical iPhone and open the real Pro paywall; verify the €9.99 Lifetime product loads from Apple.
3. Capture the real Pro paywall screenshot and upload it as the Lifetime IAP App Review Screenshot.
4. Perform real sandbox/TestFlight Lifetime purchase validation: Free -> purchase -> Pro, relaunch persistence, then explicit Restore Purchases path on an appropriate clean/reinstalled test state.
5. Perform physical-device persistence, notification, VoiceOver, Dynamic Type and Light/Dark spot checks.
6. Independently verify `https://kamilunavo.com/keepmeter/privacy` and `https://kamilunavo.com/support` publicly.
7. Finish/review App Store listing, App Privacy and EU DSA/account settings in App Store Connect.
8. Only after the above gates are green, prepare the final App Store submission.