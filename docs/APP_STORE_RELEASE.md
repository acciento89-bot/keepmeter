# KeepMeter — App Store Release Checklist

Last updated: 2026-08-19
Status: PRE-TESTFLIGHT / POPULATED SIMULATOR QA GREEN / APP STORE CONNECT + PHYSICAL-DEVICE QA OPEN

`docs/PROJECT_STATE.md` is the authoritative overall handoff. This file tracks App Store-facing release work.

## Locked technical values

- App target: `KeepMeter`
- Bundle ID: `de.kamilunavo.keepmeter`
- Marketing version: `0.1.0`
- Build number: `1`
- iOS 17.0+, iPhone only
- Category: Utilities
- StoreKit Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Monetization: one-time Non-Consumable Lifetime Pro; no subscription in v1
- Free limit: 5 active purchases through centralized `AccessPolicy`

## Branding / binary release assets

DONE + CI-gated:
- public/working v1 name `KeepMeter` (operational lock, not formal trademark clearance)
- final 1024×1024 opaque AppIcon
- asset catalog wired to Debug + Release
- Privacy Manifest bundled in Release
- `NSPrivacyTracking = false`
- UserDefaults Required Reason `CA92.1`
- Release bundle Privacy Manifest must plist-match source

## Lifetime Pro App Store Connect handoff

Exact entry data lives in `docs/IAP_LIFETIME_PRO.md`.

Locked:
- Type: Non-Consumable
- Reference Name: `KeepMeter Lifetime Pro`
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Germany launch-price decision: €9.99 one-time / matching App Store Connect price point
- German Display Name: `KeepMeter Pro – Lifetime`
- German Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`
- English Display Name: `KeepMeter Pro Lifetime`
- English Description: `Unlimited active purchases. Pay once.`

PR #18 adds hard CI for exact product identity/copy and App Store metadata limits.

## App Store listing source

Machine-readable locked v1 listing source: `metadata/AppStoreListing.json`.

Locales:
- `de-DE`
- `en-US`

PR #18 adds `ci/app-store-listing-preflight.py` to validate:
- app name <=30 chars
- subtitle <=30 chars
- promotional text <=170 chars
- description <=4000 chars
- keywords <=100 UTF-8 bytes

The listing copy in App Store Connect should be copied from this source, not retyped from old chat messages.

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

Prepared current-v1 App Store answer: **Data Not Collected / Tracking: No**, subject to mandatory recheck against the final release-candidate binary. Any analytics, crash SDK, cloud sync, backend, push-token collection, remote AI/OCR, ads or other off-device collection triggers a full re-audit.

## Public web URLs

Website source merge in `acciento89-bot/kamilunavo`: `afd809da2f814625b1cf45f6920c958897fb5398`.

Prepared source:
- bilingual KeepMeter privacy page
- KeepMeter added to shared Kamilunavo support page

Intended values after public live verification:
- Privacy Policy: `https://kamilunavo.com/keepmeter/privacy`
- Support: `https://kamilunavo.com/support`

Source merge is **not** proof of deployment. Both URLs remain release-open until verified live.

## Automated runtime evidence

Gate 15 — PR #15 — workflow `32215165699` — merge `9c5b33bf0a0123afe243a0b32bd4d0139537cd82`:
- booted iPhone Simulator install
- English/Light onboarding
- German/Dark dashboard
- terminate/relaunch
- runtime screenshots
- Release build + Privacy Manifest check

Gate 16 — PR #16 — workflow `32216276685` — merge `14f265b4fee61d2be635cb2ba0ed15b994904924`:
- centralized five-active-purchase Free limit
- direct Free boundary + Pro-bypass tests

Gate 17 — PR #17 — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6`:
- fresh English/Light onboarding
- deterministic DEBUG-only realistic purchases seeded into real app SwiftData
- populated English/Light dashboard with RETURN? + KEEP candidates
- app terminated/relaunched without reseeding
- persisted IDs, prices, usage counts, active outcomes and DecisionEngine states verified after relaunch
- persisted German/Dark dashboard rendered from a confirmed `.active` SwiftUI scene
- per-launch unique runtime token prevents false-positive `simctl launch` results
- native screenshot-signal gate rejects black/near-uniform screenshots
- final screenshots manually inspected and clean
- Release build scans out all DEBUG runtime markers/demo data
- Release Privacy Manifest verification passes

Gate 17 runtime artifact: `keepmeter-runtime-screenshots`, artifact ID `9364151762` (temporary CI retention).

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

Physical/Apple-side OPEN:
- [ ] physical iPhone fresh install/onboarding
- [ ] physical force-quit/relaunch persistence
- [ ] keep + return flows and archived read-only behavior on device
- [ ] sixth-active-purchase Free limit interaction
- [ ] Lifetime purchase unlocks Pro
- [ ] Restore re-establishes Lifetime entitlement
- [ ] notification permission flow on device
- [ ] at least one actual local notification delivered
- [ ] broader Light/Dark important-screen pass
- [ ] Dynamic Type device spot-check
- [ ] VoiceOver navigation pass
- [ ] signed Release Archive

## App Store Connect / TestFlight blockers

Repository-side DONE/PREPARED:
- [x] final AppIcon
- [x] Privacy Manifest
- [x] exact Lifetime Pro identity/copy/price decision prepared
- [x] exact reviewer notes/path prepared
- [x] DE/EN App Store listing source prepared
- [x] App Privacy answer handoff prepared
- [x] KeepMeter privacy/support website source prepared

Still external/runtime:
- [ ] verify privacy URL live
- [ ] verify support URL live
- [ ] create/verify App Store Connect app record
- [ ] create Non-Consumable `de.kamilunavo.keepmeter.pro.lifetime`
- [ ] configure €9.99 launch price / availability
- [ ] enter DE/EN IAP metadata + reviewer notes
- [ ] upload IAP review screenshot
- [ ] enter final App Store listing metadata
- [ ] complete App Privacy answers against final binary
- [ ] signed Archive
- [ ] first TestFlight upload
- [ ] sandbox/TestFlight Lifetime purchase + restore

## Release rule

Do not call KeepMeter release-ready solely because Simulator CI is green. The first TestFlight build should happen only after the repository gates remain green and the necessary Apple-side configuration/device checks are ready. Do not burn intermediate TestFlight build numbers.
