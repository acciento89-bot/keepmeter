# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — APP STORE CONNECT HANDOFF CI-GATED + ARM64 RUNTIME + REQUIRED STOREKIT ENTITLEMENT + GUARDED TESTFLIGHT LANE + SIGNING PREFLIGHT GREEN / LIVE URL + APPLE ACCOUNT + PHYSICAL DEVICE GATES OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `968987a52bc675b27451785618a6132fe3eee538`

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

## Native target / App Store identity

- SwiftUI + SwiftData + UserNotifications + StoreKit 2.
- iOS 17+; iPhone only.
- Bundle ID `de.kamilunavo.keepmeter`.
- Marketing version `0.1.0`, build `1`.
- Utilities category; generated Info.plist.
- Shared scheme archives Release and has `buildForArchiving = YES`.
- Target uses Automatic Signing.
- Gate #20 locks Apple team `TKG684N5GL` in versioned signing configuration and CI preflight.
- Gate #22 locks the first manual TestFlight lane to exact release identity `0.1.0 (1)` until deliberately changed.
- Gate #23 locks the prepared App Store Connect record values in `metadata/AppStoreConnectSetup.json`: platform iOS, name `KeepMeter`, primary language German, bundle `de.kamilunavo.keepmeter`, SKU `keepmeter-ios-001`, Utilities, Free base app, version `0.1.0`, build `1`.
- Gate #23 deliberately leaves Apple-account DSA trader status unresolved for verification in App Store Connect; repository data is not treated as a legal determination.

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
- Gate #20 reran the complete running-app persistence/visual path after signing/runtime hardening and passed unchanged.
- Gate #21 required-CI promotion reran the same full normal runtime/Release pipeline on workflow `32284909516` and passed unchanged alongside the now-required StoreKit entitlement job.
- Gate #22 reran the complete normal runtime/Release pipeline on workflow `32287632445` after adding the guarded manual TestFlight lane; persistence/runtime remained green.
- Gate #23 reran the complete normal runtime/Release pipeline on workflow `32290236121` after adding the machine-readable App Store Connect setup and required handoff preflight; persistence/runtime remained green.

Still open:
- equivalent force-quit/relaunch check on a physical iPhone.

## StoreKit / Lifetime Pro

Product identity locked in main:
- Type: Non-Consumable.
- Reference Name: `KeepMeter Lifetime Pro`.
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.
- Germany launch-price decision: **€9.99 one-time** / matching current App Store Connect price point.
- No subscription in v1.
- Family Sharing off for v1.

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
- `docs/IAP_LIFETIME_PRO.md` is the exact human App Store Connect IAP handoff.
- Gate #21 adds a real iOS Simulator-hosted StoreKitTest/XCTest against the production `EntitlementStore` and exact `KeepMeter.storekit` Lifetime product.
- the Gate #21 test proves Free start -> real `SKTestSession` Lifetime transaction -> Pro unlock through `Transaction.updates` / `Transaction.currentEntitlements` -> entitlement recovery in a newly-created `EntitlementStore` -> entitlement removal after clearing the StoreKitTest transaction.
- external StoreKitTest transaction propagation uses a bounded ~5-second wait instead of an immediate race-prone assertion; no fake entitlement, DEBUG Pro bypass or weakened assertion is used.
- the StoreKit job is required CI: `continue-on-error` was removed in PR #25 and a StoreKit failure makes the workflow fail.
- Gate #22 reran the required StoreKit lane unchanged in workflow `32287632445`; job `96180829076` passed before merge.
- Gate #23 mirrored the exact Lifetime IAP into `metadata/AppStoreConnectSetup.json` and reran the required StoreKit lane unchanged; workflow `32290236121`, job `96189098313` passed before merge.

Still open:
- matching App Store Connect Lifetime IAP creation/configuration.
- release-candidate IAP review screenshot.
- sandbox/TestFlight purchase + entitlement + explicit Restore Purchases (`AppStore.sync()`) validation.

## App Store listing / App Store Connect handoff

Gate #18 merged machine-readable v1 listing copy at `metadata/AppStoreListing.json` plus `ci/app-store-listing-preflight.py`.

Gate #23 adds:
- `metadata/AppStoreConnectSetup.json` as the exact machine-readable ASC record/IAP/privacy/TestFlight setup source.
- immutable prepared SKU `keepmeter-ios-001`.
- `docs/APP_STORE_CONNECT_RUNBOOK.md` with the exact operational order from Apple account checks through first TestFlight and sandbox restore validation.
- refreshed `docs/APP_STORE_RELEASE.md` and `docs/IAP_LIFETIME_PRO.md` aligned to Gates #21/#22/#23.
- `ci/app-store-connect-handoff-preflight.py`, now a required normal-CI step.

The Gate #23 preflight cross-checks:
- app-record platform/name/primary language/bundle/SKU/category/base-price/version/build.
- DE/EN locale set against `metadata/AppStoreListing.json`.
- Privacy and Support URL identities while retaining an explicit `liveVerified = false` deployment boundary.
- Data Not Collected / Tracking No plus mandatory final-binary privacy recheck.
- exact Lifetime Pro product identity, launch-price decision, localizations and App Review information requirements.
- unresolved EU DSA account/app verification sentinel.
- guarded TestFlight workflow path/main/confirmation/build-number-management and required ASC secret names.

Do not retype Apple-facing metadata from old chat messages; use these repository sources.

## Privacy

`KeepMeter/PrivacyInfo.xcprivacy` is bundled and CI-gated.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- UserDefaults Required Reason `CA92.1`.
- Release bundle manifest must plist-match source.

Gate #18 merged `docs/APP_PRIVACY_HANDOFF.md` with the current intended App Store privacy answer: **Data Not Collected / Tracking: No**, subject to a mandatory final binary re-audit. Re-audit immediately if analytics, crash SDKs, networking/data collection, push-token handling or other off-device data behavior is added.

Gate #23 mirrors that handoff into `metadata/AppStoreConnectSetup.json` and makes the final-binary recheck flag mandatory in required CI. This remains a prepared answer, not proof that Apple-side App Privacy has been entered.

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

Latest required-CI runtime artifact:
- Gate #23 workflow `32290236121`.
- artifact `9379371189` (`keepmeter-runtime-screenshots`).
- runtime screenshot generation and native visual-signal validation passed.
- this Gate #23 artifact was not manually inspected in this pass; the latest manually inspected screenshots remain Gate #20 artifact `9374353233`, which was clean for fresh EN/Light onboarding, populated EN/Light dashboard and persisted DE/Dark dashboard.

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

Gate #20 extends hosted CoreSimulator hardening without weakening the app evidence:
- a timed-out `simctl io screenshot` client is non-authoritative only if the same simulator still materializes a stable PNG that passes `sips` and the native visual-signal validator.
- screenshot capture may retry once on the same installed simulator.
- if the already-installed simulator cannot produce the unique active-scene sentinel because its UI services are unhealthy, the harness may perform exactly one shutdown/reboot of the same UDID.
- the existing KeepMeter installation must still resolve after reboot and the normal active-scene proof must then pass.
- no alternate simulator is allowed after successful installation.

Gate #21 adds a separate required StoreKit lane:
- pinned to Xcode 26.2 and iOS 26.2 on `macos-26` arm64.
- uses an iPhone 17 Pro Max simulator and the actual app/test target rather than the rejected macOS off-device harness.
- exercises the exact Lifetime product and real production entitlement path.
- remains independent of App Store Connect credentials, sandbox accounts and TestFlight.

Gate #22 adds a guarded manual TestFlight release lane without weakening required CI:
- `.github/workflows/testflight.yml` is `workflow_dispatch`-only; no push, pull-request or schedule trigger is permitted.
- upload is allowed only from `main` and only after typing exact confirmation `UPLOAD_KEEP_METER_0_1_0_BUILD_1`.
- release identity is checked again before upload: bundle `de.kamilunavo.keepmeter`, version `0.1.0`, build `1`.
- StoreKit metadata, App Store listing, localization and Release preflights run again before signing.
- signed archive path uses Xcode 26.2, `generic/platform=iOS`, `Config/Signing.xcconfig`, Automatic Signing and team `TKG684N5GL`.
- App Store Connect export is locked to `app-store-connect` / `upload`, with `manageAppVersionAndBuildNumber = false`.
- temporary ASC private key cleanup is always-run.
- `ci/testflight-workflow-preflight.py` is required by normal CI and rejects automatic triggers or weakened safeguards.
- normal CI only validates the upload workflow statically; it does not execute the TestFlight workflow, sign an archive or upload a build.

Gate #23 adds an App Store Connect handoff gate without pretending to have Apple-side access:
- exact prepared ASC app-record values live in `metadata/AppStoreConnectSetup.json`.
- SKU `keepmeter-ios-001` is locked before app-record creation.
- Privacy/Support URLs remain explicitly not-live-verified in repository state.
- EU DSA trader status remains an explicit account/app verification item rather than a guessed legal answer.
- `ci/app-store-connect-handoff-preflight.py` is required by normal CI and cross-checks the ASC setup against listing, IAP and TestFlight sources.
- full normal runtime/Release and required StoreKit lanes remained green on workflow `32290236121` before merge.

## Website / public release pages

Kamilunavo website source merge `afd809da2f814625b1cf45f6920c958897fb5398` added:
- bilingual KeepMeter-specific privacy page source.
- KeepMeter to the shared Kamilunavo support page.

Kamilunavo website merge `6cf96be83b29e74ad5414cc02e4997d3508e6f57` further hardened `/support` for App Store use by adding the already-published operator/business address and a direct imprint link while keeping `support@kamilunavo.com` visible.

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

Gate #20 merged and verifies:
- versioned `Config/Signing.xcconfig` with `DEVELOPMENT_TEAM = TKG684N5GL` and Automatic Signing.
- hard CI assertions for `CODE_SIGN_STYLE = Automatic` and exact team ID.
- hard shared-scheme Release archive assertions.
- `docs/SIGNING_ARCHIVE_HANDOFF.md` with the future signed archive/export pattern and explicit credential boundary.
- complete metadata + runtime + screenshot + Release QA remained green on workflow `32276400054` before merge.

Gate #22 merged and verifies:
- a manual-only `.github/workflows/testflight.yml` with explicit main/build confirmation guard.
- exact `0.1.0 (1)` archive identity must match before export/upload.
- KeepMeter-local ASC secrets are required only at intentional dispatch time.
- archive and export both use App Store Connect key authentication and provisioning updates.
- export explicitly disables Apple build-number management.
- `ci/testflight-workflow-preflight.py` is part of required normal CI and passed in workflow `32287632445`.
- full normal runtime/Release job `96180829650` and required StoreKit job `96180829076` passed before PR #27 merged.

Gate #23 verifies the prepared Apple-side handoff while preserving the credential boundary:
- exact app-record/IAP/privacy/TestFlight values are machine-readable and CI-gated.
- KeepMeter repository ASC secret names are locked, but the secrets themselves were not added.
- no App Store Connect API was invoked, no signed physical-device archive was produced, and no TestFlight workflow was dispatched.

## Verified gates

1–16: MVP, visual polish, StoreKit/reminder hardening, notification QA, local StoreKit environment, data integrity/accessibility, file-backed SwiftData reopen, Release compile, App Store preflight, brand lock, AppIcon gate, entitlement recovery, product/localization rules, Privacy Manifest, booted Simulator runtime, centralized AccessPolicy — all GREEN and merged.

17. PR #17 — populated Simulator persistence + active-scene launch proof + screenshot visual-signal + Release QA isolation — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6` — GREEN; screenshots manually inspected.
18. PR #19 — arm64 `macos-26` runtime infrastructure + bounded two-device pre-install fallback — workflow `32257672022` — merge `1e819921a977614c6364f31f4abab0170ed9ef1b` — GREEN; artifact `9367177687` manually inspected.
19. PR #18 — App Store/IAP/listing/privacy handoff on Gate #19 arm64 base — workflow `32258911074` — merge `85160a6e66774bdbd1128fa066abc5bd66371d52` — GREEN; artifact `9367666345` manually inspected.
20. PR #20 — Apple team/signing/archive preflight + same-device CoreSimulator lifecycle hardening — workflow `32276400054` — merge `4d63db7d32ec24ffd4beb59e506369e2c25ba2c1` — GREEN; artifact `9374353233` manually inspected.
21. PR #24 + PR #25 — iOS Simulator StoreKitTest Lifetime entitlement proof + promotion to required CI. PR #24 fixed the asynchronous entitlement-propagation race and passed experimental StoreKit job `96167793044` in workflow `32283455910`, then merged as `e3c0bf0dea731e31a36a906b9431c0df6044f52f`. PR #25 removed `continue-on-error`, renamed the job to required `StoreKit entitlement XCTest`, and workflow `32284909516` passed both the required StoreKit job `96172034950` and full normal build job `96172035320`; StoreKit result: 1 test, 0 failures, `TEST SUCCEEDED`; merge `222464d21c888fdae5d01b07b6569a76ca2749a7` — GREEN. Historical PR #23 is not treated as Gate #21 proof because it merged while the experimental StoreKit job was still allowed to fail.
22. PR #27 — guarded manual signed Archive/TestFlight lane + required static workflow-safety preflight — workflow `32287632445` — StoreKit job `96180829076` GREEN, full normal build/runtime/Release job `96180829650` GREEN, runtime artifact `9378499165` — merge `8828fc2f706d2dec44ea48536d4928026aaa9d75` — GREEN. No TestFlight workflow dispatch or upload occurred.
23. PR #29 — exact App Store Connect machine-readable setup + immutable SKU + Apple-side release runbook + required ASC handoff preflight — workflow `32290236121` — StoreKit job `96189098313` GREEN, full normal build/runtime/Release job `96189098570` GREEN, runtime artifact `9379371189` — merge `968987a52bc675b27451785618a6132fe3eee538` — GREEN. No App Store Connect mutation, credential provisioning, signed archive or TestFlight upload occurred.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Release status

DONE / automated or repository-prepared:
- functional Debug + Release builds.
- AppIcon and Privacy Manifest.
- DecisionEngine / AccessPolicy / EN-DE regression tests.
- file-backed and running-app SwiftData persistence evidence.
- representative Light/EN and Dark/DE visuals with anti-black-screen gate.
- DEBUG QA isolation from Release binary.
- required iOS CI proven on `macos-26` arm64 with bounded pre-install fallback and same-device recovery.
- exact Lifetime Pro v1 IAP identity/copy/price handoff.
- required StoreKitTest/XCTest proof of the real Free -> Lifetime Pro entitlement/recovery/removal path on Xcode 26.2 / iOS 26.2.
- exact DE/EN App Store listing source and field-limit checks.
- App Privacy handoff.
- Apple team `TKG684N5GL`, Automatic Signing and Release archive scheme locked by CI.
- guarded manual TestFlight upload workflow prepared and CI-locked against automatic triggering or build-number drift.
- exact App Store Connect app-record handoff prepared with SKU `keepmeter-ios-001` and required CI cross-check.
- exact Apple-side operational runbook prepared.
- Kamilunavo support source hardened with direct support/business contact information.

OPEN / external or device-only:
- live deployment/verification of KeepMeter privacy and support URLs.
- current Apple agreements/account access and DSA trader-status/app-setting verification.
- App Store Connect app record creation using the locked bundle/SKU.
- Lifetime IAP creation/configuration and review screenshot.
- final App Store listing/App Privacy entry in App Store Connect.
- KeepMeter repository ASC secret provisioning.
- physical-device persistence/notification/VoiceOver/Dynamic Type checks.
- first signed Release Archive.
- first TestFlight upload.
- sandbox/TestFlight Lifetime Pro purchase + entitlement + explicit restore.

No TestFlight build has been uploaded yet.

## Immediate next steps

1. Deploy/verify `https://kamilunavo.com/keepmeter/privacy` and `https://kamilunavo.com/support` live when authenticated server/Portainer deployment access is available.
2. In App Store Connect, verify current agreements/account access and the EU DSA trader-status/account/app setting; do not infer this from repository state.
3. Create the KeepMeter App Store Connect record using the exact repository handoff: iOS, `KeepMeter`, German primary language, bundle `de.kamilunavo.keepmeter`, SKU `keepmeter-ios-001`, Utilities, Free app, version `0.1.0`.
4. Create/configure Lifetime Pro exactly as `de.kamilunavo.keepmeter.pro.lifetime`, Non-Consumable, €9.99 Germany launch decision, DE/EN metadata, reviewer notes and release-candidate review screenshot.
5. Provision `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY_B64` in the KeepMeter repository only after the Apple-side record is correct.
6. Perform the physical-device persistence/notification/accessibility preflight.
7. When steps 1–6 are ready, manually dispatch `KeepMeter TestFlight` from `main` with confirmation `UPLOAD_KEEP_METER_0_1_0_BUILD_1`; that single run creates the signed Release Archive and uploads exact build `0.1.0 (1)`.
8. Validate the real sandbox/TestFlight Lifetime Pro purchase, entitlement persistence and explicit Restore Purchases path before App Store submission.
