# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — APP STORE HANDOFF + ARM64 RUNTIME GREEN / SIGNING + APPLE DEVICE GATES OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `85160a6e66774bdbd1128fa066abc5bd66371d52`

## Handoff rule

This file is the authoritative ongoing KeepMeter state.

For future work:
1. Read this file first.
2. Inspect current `main`, open PRs and CI.
3. Continue from `Immediate next steps`.
4. Update this file after every major pass.
5. Normal KeepMeter work is documented here; no parallel App Factory state update is required.

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

## Native target

- SwiftUI + SwiftData + UserNotifications + StoreKit 2.
- iOS 17+; iPhone only.
- Bundle ID `de.kamilunavo.keepmeter`.
- Marketing version `0.1.0`, build `1`.
- Utilities category; generated Info.plist.
- Shared scheme archives Release and has `buildForArchiving = YES`.
- Target uses Automatic Signing.
- Gate #20 is currently validating Apple team `TKG684N5GL` as a separate signing-readiness pass.

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
- `AccessPolicy.freeActivePurchaseLimit = 5` is the single Free-limit source of truth.
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
- Gate #17 seeds deterministic purchases into the real running iOS Simulator app, terminates/relaunches without reseeding and verifies the same SwiftData IDs, prices, usage counts, outcomes and DecisionEngine results through an in-app DEBUG probe.
- Gate #18 reran the same populated persistence/visual path on the final App Store metadata state and passed.

Still open:
- equivalent force-quit/relaunch check on a physical iPhone.

## StoreKit / Lifetime Pro

Product identity locked in main:
- Type: Non-Consumable.
- Reference Name: `KeepMeter Lifetime Pro`.
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Germany launch-price decision: **€9.99 one-time** / matching App Store Connect price point.
- No subscription in v1.

Localized customer metadata locked in main:
- DE Display Name: `KeepMeter Pro – Lifetime`.
- DE Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`
- EN Display Name: `KeepMeter Pro Lifetime`.
- EN Description: `Unlimited active purchases. Pay once.`

Implemented/hardened:
- local `.storekit` NonConsumable test product.
- shared Debug scheme references local StoreKit config.
- `ci/storekit-metadata-preflight.py` checks exact product identity/copy and App Store field limits.
- DEBUG Settings diagnostics for product/price/entitlement.
- `Transaction.currentEntitlements` refreshes independently of product metadata loading.
- verified `Transaction.updates` and `Transaction.unfinished` handled.
- access refresh occurs before `transaction.finish()`.
- unverified transactions never unlock Pro.
- `AppStore.sync()` only behind explicit Restore Purchases.
- `docs/IAP_LIFETIME_PRO.md` is the exact App Store Connect IAP handoff.

Still open:
- interactive StoreKit Free -> Pro -> Restore automation/session.
- matching App Store Connect Lifetime IAP creation/configuration.
- release-candidate IAP review screenshot.
- sandbox/TestFlight purchase + entitlement + restore.

## App Store listing handoff

Gate #18 merged a machine-readable v1 source at `metadata/AppStoreListing.json` plus `ci/app-store-listing-preflight.py`.

The preflight enforces Apple-facing size limits for DE/EN name, subtitle, promotional text, description and keyword bytes. Gate #18 workflow passed all listing checks before merge.

`docs/APP_STORE_RELEASE.md` remains the human release checklist and screenshot plan.

## Privacy

`KeepMeter/PrivacyInfo.xcprivacy` is bundled and CI-gated.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- UserDefaults Required Reason `CA92.1`.
- Release bundle manifest must plist-match source.

Gate #18 merged `docs/APP_PRIVACY_HANDOFF.md` with the current intended App Store privacy answer: **Data Not Collected / Tracking: No**, subject to a mandatory final binary re-audit. Re-audit immediately if analytics, crash SDKs, networking/data collection, push-token handling or other off-device data behavior is added.

## Notifications

Implemented:
- local reminders around entered return date.
- stable DE/EN dynamic format localization.
- Settings exposes authorization state, request action and iOS Settings handoff.
- authorization state refreshes when app becomes active.

Still open:
- real scheduled-notification delivery on physical device.

## Localization / accessibility / visual

- polished native UI across Onboarding, Dashboard, Add, Detail, Insights, Archive, Settings and Paywall.
- Dynamic Type adaptive layouts on major screens.
- VoiceOver grouping/hiding applied where appropriate in source.
- `ci/localization-preflight.py` enforces EN/DE key parity, no duplicates/empties and matching format placeholders.
- native `ci/RuntimeScreenshotSignal.swift` rejects black/near-uniform screenshots.

Latest Gate #18 runtime artifact:
- workflow `32258911074`.
- artifact `9367666345`.
- fresh EN/Light onboarding manually inspected clean.
- populated EN/Light dashboard manually inspected clean.
- persisted DE/Dark dashboard manually inspected clean.
- same deterministic KEEP / RETURN? purchase data survived relaunch.

Still open:
- broader all-important-screen physical-device Light/Dark review.
- physical/runtime VoiceOver pass.
- physical Dynamic Type spot-check.

## Runtime CI hardening

Required runner: **`macos-26` Apple Silicon / arm64**.

Gate #17 provides:
- DEBUG-only deterministic purchase seeding.
- DEBUG-only persistence verification sentinel.
- unique per-launch DEBUG token.
- launch proof only when SwiftUI scene is actually `.active`.
- bounded foreground nudge.
- visual-signal validation for every runtime screenshot.
- Release binary scan rejecting every DEBUG runtime token, sentinel name and seeded demo value.

Gate #19 adds infrastructure hardening without weakening app assertions:
- migrated required CI from `macos-26-intel` to `macos-26` arm64.
- setup may try at most two distinct iPhone simulator UDIDs.
- fallback is permitted only before KeepMeter has successfully installed.
- `bootstatus` and `simctl install` client timeouts are non-authoritative; actual app-container materialization after the full bounded install/poll window is the setup authority.
- once KeepMeter installs, there is no alternate-device retry for launch, persistence, screenshots or Release validation.

## Website / public release pages

Kamilunavo website source merge `afd809da2f814625b1cf45f6920c958897fb5398` added:
- bilingual KeepMeter-specific privacy page source.
- KeepMeter to the shared Kamilunavo support page.

Intended App Store URLs after live-deployment verification:
- `https://kamilunavo.com/keepmeter/privacy`
- `https://kamilunavo.com/support`

Source merge is not proof of public deployment. No generic SSH/Portainer deploy workflow or connected deployment tool is currently available for `acciento89-bot/kamilunavo`, so live deployment verification remains open.

## Signing / Archive path

Known Kamilunavo Apple team: `TKG684N5GL`.

Known-good release model from ZweiCheck:
- Automatic Signing.
- App Store Connect API key credentials supplied to GitHub Actions as `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY_B64` in that repository.
- archive with `xcodebuild` for `generic/platform=iOS` and `-allowProvisioningUpdates`.
- export with `method = app-store-connect`, `destination = upload`, `signingStyle = automatic`, matching team ID.

Do not assume ZweiCheck repository secrets automatically exist in KeepMeter.

Gate #20 (`agent/signing-preflight`) currently adds:
- `DEVELOPMENT_TEAM = TKG684N5GL` to KeepMeter Debug + Release.
- hard CI assertions for `CODE_SIGN_STYLE = Automatic` and exact team ID.
- hard shared-scheme archive assertions.
- `docs/SIGNING_ARCHIVE_HANDOFF.md`.

Gate #20 intentionally does not add credentials, certificates, provisioning profiles, a signed archive or a TestFlight upload.

## Verified gates

1–16: MVP, visual polish, StoreKit/reminder hardening, notification QA, local StoreKit environment, data integrity/accessibility, file-backed SwiftData reopen, Release compile, App Store preflight, brand lock, AppIcon gate, entitlement recovery, product/localization rules, Privacy Manifest, booted Simulator runtime, centralized AccessPolicy — all GREEN and merged.

17. PR #17 — populated Simulator persistence + active-scene launch proof + screenshot visual-signal + Release QA isolation — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6` — GREEN; screenshots manually inspected.
18. PR #19 — arm64 `macos-26` runtime infrastructure + bounded two-device pre-install fallback — workflow `32257672022` — merge `1e819921a977614c6364f31f4abab0170ed9ef1b` — GREEN; artifact `9367177687` manually inspected.
19. PR #18 — App Store/IAP/listing/privacy handoff on Gate #19 arm64 base — workflow `32258911074` — merge `85160a6e66774bdbd1128fa066abc5bd66371d52` — GREEN; artifact `9367666345` manually inspected.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Release status

DONE / automated:
- functional Debug + Release builds.
- AppIcon and Privacy Manifest.
- DecisionEngine / AccessPolicy / EN-DE regression tests.
- file-backed and running-app SwiftData persistence evidence.
- representative Light/EN and Dark/DE visuals with anti-black-screen gate.
- DEBUG QA isolation from Release binary.
- required iOS CI proven on `macos-26` arm64 with bounded pre-install fallback.
- exact Lifetime Pro v1 IAP handoff.
- exact DE/EN App Store listing source and field-limit checks.
- App Privacy handoff.

OPEN:
- Gate #20 signing/team/archive preflight merge.
- live verification/deployment of public support/privacy URLs.
- App Store Connect app record + Lifetime IAP creation/configuration.
- interactive StoreKit purchase/restore automation or session.
- physical-device persistence/notification/VoiceOver/Dynamic Type checks.
- signed Release Archive.
- first TestFlight upload.
- sandbox/TestFlight Lifetime Pro purchase + restore.

No TestFlight build has been uploaded yet.

## Immediate next steps

1. Make Gate #20 fully green against the Gate #18 main state and merge only after the complete metadata + runtime + Release pipeline passes.
2. Prepare a proper StoreKitTest/XCTest purchase-entitlement test rather than DEBUG fake entitlement; keep it experimental/non-blocking until Xcode 26.6 behavior is proven stable.
3. Verify/deploy public KeepMeter privacy/support pages when authenticated server deployment access is available.
4. Create/configure the App Store Connect app record and Lifetime IAP when authenticated Apple-side access is available.
5. Perform physical-device notification/persistence/accessibility gates.
6. Only after those gates create the first signed TestFlight build; do not burn intermediate TestFlight build numbers.
