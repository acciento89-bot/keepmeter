# KeepMeter — App Store Release Checklist

Last updated: 2026-08-19
Status: PRE-TESTFLIGHT / GATES 1–22 GREEN / APP STORE CONNECT + LIVE URL + PHYSICAL-DEVICE GATES OPEN

`docs/PROJECT_STATE.md` is the authoritative overall handoff. This file tracks App Store-facing release work.

Exact operational App Store Connect order: `docs/APP_STORE_CONNECT_RUNBOOK.md`.
Machine-readable App Store Connect values: `metadata/AppStoreConnectSetup.json`.

## Locked technical / App Store values

- App target: `KeepMeter`
- Platform: iOS
- App Store name: `KeepMeter`
- Primary language: German
- Bundle ID: `de.kamilunavo.keepmeter`
- App Store Connect SKU: `keepmeter-ios-001`
- Marketing version: `0.1.0`
- Build number: `1`
- iOS 17.0+, iPhone only
- Primary category: Utilities
- Base app price: Free
- StoreKit Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Monetization: one-time Non-Consumable Lifetime Pro; no subscription in v1
- Free limit: 5 active purchases through centralized `AccessPolicy`
- First TestFlight upload confirmation: `UPLOAD_KEEP_METER_0_1_0_BUILD_1`

The SKU is intentionally locked before App Store Connect app-record creation because it is an internal identifier that cannot be changed after the app is added. Do not invent a different SKU in App Store Connect.

## Branding / binary release assets

DONE + CI-gated:
- public/working v1 name `KeepMeter` (operational lock, not formal trademark clearance)
- final 1024×1024 opaque AppIcon
- asset catalog wired to Debug + Release
- Privacy Manifest bundled in Release
- `NSPrivacyTracking = false`
- UserDefaults Required Reason `CA92.1`
- Release bundle Privacy Manifest must plist-match source
- bundle/version/build release identity locked for the first TestFlight lane

## Lifetime Pro App Store Connect handoff

Exact entry data lives in `docs/IAP_LIFETIME_PRO.md` and is mirrored in `metadata/AppStoreConnectSetup.json`.

Locked:
- Type: Non-Consumable
- Reference Name: `KeepMeter Lifetime Pro`
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Germany launch-price decision: €9.99 one-time / matching current App Store Connect price point
- Family Sharing: off for v1
- German Display Name: `KeepMeter Pro – Lifetime`
- German Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`
- English Display Name: `KeepMeter Pro Lifetime`
- English Description: `Unlimited active purchases. Pay once.`
- reviewer notes required
- release-candidate IAP review screenshot required

CI enforces exact product identity/copy and current field-length limits. Gate #21 additionally proves the production `EntitlementStore` path against StoreKitTest/XCTest; the real sandbox/TestFlight purchase and explicit Restore Purchases path remain Apple-side gates.

## App Store listing source

Machine-readable locked v1 listing source: `metadata/AppStoreListing.json`.

Locales:
- `de-DE`
- `en-US`

`ci/app-store-listing-preflight.py` validates:
- app name <=30 chars
- subtitle <=30 chars
- promotional text <=170 chars
- description <=4000 chars
- keywords <=100 UTF-8 bytes

The listing copy in App Store Connect must be copied from this source, not retyped from old chat messages.

## App Privacy handoff

`docs/APP_PRIVACY_HANDOFF.md` records the intended current-v1 answers.

Current audited architecture:
- no account required
- no Kamilunavo backend for core data
- purchase/usage records stay local in SwiftData
- app preferences stay local
- notifications are local
- StoreKit handles Lifetime Pro
- no analytics SDK
- no advertising SDK
- no cross-app tracking

Prepared current-v1 App Store answer: **Data Not Collected / Tracking: No**, subject to mandatory recheck against the final release-candidate binary and integrated third-party code. Any analytics, crash SDK, cloud sync, backend, push-token collection, remote AI/OCR, ads or other off-device collection triggers a full re-audit.

## EU / DSA compliance gate

Do not guess the Apple-account trader declaration from repository data.

Before EU distribution:
- verify the current account-level Digital Services Act trader-status declaration;
- verify the app-specific setting in App Store Connect;
- if the account/app distributes in the EU as a trader, verify Apple's required public contact-details workflow is complete.

`metadata/AppStoreConnectSetup.json` intentionally stores this as an unresolved Apple-account verification gate rather than claiming a legal status.

## Public web URLs

Prepared source:
- bilingual KeepMeter-specific privacy page
- shared Kamilunavo support page
- support page now directly exposes support email, existing operator/business address and a full imprint link

Relevant website source merges:
- initial KeepMeter privacy/support preparation: `afd809da2f814625b1cf45f6920c958897fb5398`
- App-Store-oriented support contact hardening: `6cf96be83b29e74ad5414cc02e4997d3508e6f57`

Intended values after public live verification:
- Privacy Policy: `https://kamilunavo.com/keepmeter/privacy`
- Support: `https://kamilunavo.com/support`

Source merge is **not** proof of deployment. Both URLs remain release-open until verified live over HTTPS with the intended content.

## Automated runtime / release evidence

Gates 1–16 established the MVP, native UI, data integrity, StoreKit/reminder hardening, Privacy Manifest, listing/IAP preflights, runtime smoke and centralized AccessPolicy.

Gate 17 — PR #17 — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6`:
- populated running-app SwiftData persistence across terminate/relaunch
- unique active-scene launch proof
- Light/EN and Dark/DE runtime screenshots
- screenshot visual-signal gate
- Release DEBUG-hook isolation
- screenshots manually inspected clean

Gate 18 — PR #19 — workflow `32257672022` — merge `1e819921a977614c6364f31f4abab0170ed9ef1b`:
- required CI moved to `macos-26` arm64
- bounded pre-install simulator fallback
- artifact `9367177687` manually inspected

Gate 19 — PR #18 — workflow `32258911074` — merge `85160a6e66774bdbd1128fa066abc5bd66371d52`:
- exact App Store listing/IAP/privacy handoff on arm64 runtime base
- artifact `9367666345` manually inspected

Gate 20 — PR #20 — workflow `32276400054` — merge `4d63db7d32ec24ffd4beb59e506369e2c25ba2c1`:
- Apple team `TKG684N5GL` + Automatic Signing preflight
- Release archive scheme assertions
- same-installed-simulator runtime recovery hardening
- artifact `9374353233` manually inspected

Gate 21 — PR #24 + PR #25 — workflows `32283455910` / `32284909516` — product merge `222464d21c888fdae5d01b07b6569a76ca2749a7`:
- real iOS Simulator StoreKitTest/XCTest Lifetime entitlement test
- Free -> Lifetime Pro -> entitlement recovery/removal
- required StoreKit job `96172034950` passed: 1 test, 0 failures
- full normal job `96172035320` passed
- StoreKit job is now blocking CI; no `continue-on-error`

Gate 22 — PR #27 — workflow `32287632445` — merge `8828fc2f706d2dec44ea48536d4928026aaa9d75`:
- guarded manual signed Archive/TestFlight lane
- `workflow_dispatch` only; main-only; exact `0.1.0 (1)` confirmation
- Apple build-number management explicitly disabled
- required workflow-safety preflight passed
- StoreKit job `96180829076` passed
- full runtime/Release job `96180829650` passed
- runtime artifact `9378499165`
- **no TestFlight workflow was dispatched and no build was uploaded**

## Runtime/device checklist

Automated/simulator DONE:
- [x] fresh install/onboarding render
- [x] app launch / terminate / relaunch
- [x] realistic populated purchase dashboard
- [x] SwiftData purchase/usage relationship survives Simulator relaunch without reseeding
- [x] representative Light + Dark rendering
- [x] representative English + German rendering
- [x] screenshot anti-black/blank gate
- [x] standalone file-backed SwiftData reopen test
- [x] DecisionEngine rules
- [x] Free/Pro AccessPolicy boundaries
- [x] EN/DE localization key/format parity
- [x] Debug + Release compilation
- [x] DEBUG runtime QA isolation from Release binary
- [x] required StoreKitTest Lifetime entitlement/recovery/removal path
- [x] guarded manual TestFlight workflow safety checks

Physical/Apple-side OPEN:
- [ ] physical iPhone fresh install/onboarding
- [ ] physical force-quit/relaunch persistence
- [ ] keep + return flows and archived read-only behavior on device
- [ ] sixth-active-purchase Free limit interaction
- [ ] notification permission flow on device
- [ ] at least one actual local notification delivered
- [ ] broader Light/Dark important-screen pass
- [ ] Dynamic Type device spot-check
- [ ] VoiceOver navigation pass
- [ ] real TestFlight Lifetime purchase unlocks Pro
- [ ] real explicit Restore Purchases re-establishes Lifetime entitlement
- [ ] signed Release Archive / first TestFlight upload

## App Store Connect / TestFlight readiness

Repository-side DONE/PREPARED:
- [x] final AppIcon
- [x] Privacy Manifest
- [x] exact Lifetime Pro identity/copy/price decision prepared
- [x] exact reviewer notes/path prepared
- [x] DE/EN App Store listing source prepared
- [x] App Privacy answer handoff prepared
- [x] KeepMeter privacy/support website source prepared
- [x] support source strengthened with direct contact information
- [x] exact App Store Connect machine-readable setup prepared
- [x] App Store Connect SKU `keepmeter-ios-001` intentionally locked
- [x] exact Apple-side entry order documented in `docs/APP_STORE_CONNECT_RUNBOOK.md`
- [x] manual TestFlight signed-archive/upload lane prepared and CI-guarded

Still external/runtime:
- [ ] verify/deploy privacy URL live
- [ ] verify/deploy support URL live
- [ ] verify current Apple agreements/account access
- [ ] verify DSA trader-status/account/app setting
- [ ] create App Store Connect app record with bundle `de.kamilunavo.keepmeter` and SKU `keepmeter-ios-001`
- [ ] create Non-Consumable `de.kamilunavo.keepmeter.pro.lifetime`
- [ ] configure €9.99 launch price / availability
- [ ] enter DE/EN IAP metadata + reviewer notes
- [ ] upload release-candidate IAP review screenshot
- [ ] enter final App Store listing metadata
- [ ] complete App Privacy answers against final binary
- [ ] provision KeepMeter repo `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY_B64`
- [ ] physical-device preflight
- [ ] first signed Archive/TestFlight upload
- [ ] sandbox/TestFlight Lifetime purchase + entitlement + explicit restore

## Release rule

Do not call KeepMeter release-ready solely because Simulator CI is green. The first TestFlight build should happen only after the public URLs, App Store Connect app/IAP setup, KeepMeter release credentials and basic physical-device gates are ready. Do not burn intermediate TestFlight build numbers.
