# KeepMeter — App Store Release Checklist

Last updated: 2026-08-19
Status: PRE-TESTFLIGHT / AUTOMATED SIMULATOR QA GREEN / APP STORE CONNECT + DEVICE QA OPEN

This file tracks App Store-facing release requirements. `docs/PROJECT_STATE.md` remains the authoritative overall project handoff.

## Locked technical values

- App target: `KeepMeter`
- Bundle ID: `de.kamilunavo.keepmeter`
- Current marketing version: `0.1.0`
- Current build number: `1`
- Deployment target: iOS 17.0+
- Device family: iPhone
- App category: Utilities
- StoreKit Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Monetization: one-time non-consumable Lifetime Pro; no subscription in v1
- Free limit: 5 active purchases, enforced through centralized `AccessPolicy`

## Public branding / release assets

- Public/working v1 name: `KeepMeter`
- Name status: operationally locked for v1; not claimed as legally trademark-cleared
- Final AppIcon: DONE
- `KeepMeter/Assets.xcassets/AppIcon.appiconset`: DONE
- Master PNG: 1024×1024, opaque/no alpha
- Asset catalog connected to Xcode Resources: DONE
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`: Debug + Release
- CI hard-checks AppIcon presence, metadata, dimensions and opacity
- Debug + Release asset compilation: GREEN

## Privacy manifest baseline

- `KeepMeter/PrivacyInfo.xcprivacy`: DONE
- included in target Resources: DONE
- `NSPrivacyTracking = false`
- no tracking domains
- no collected-data types declared for current local-only v1 core
- UserDefaults Required Reason API category declared with `CA92.1`
- Release CI verifies the manifest is physically present inside the built `KeepMeter.app`
- built manifest must plist-match the source manifest

Important: re-audit App Privacy and the manifest if analytics, crash reporting, networking/data collection or additional Required Reason APIs are added.

## Lifetime Pro App Store Connect handoff

Exact product-entry details are maintained in `docs/IAP_LIFETIME_PRO.md`.

Locked v1 values:
- Type: Non-Consumable
- Reference Name: `KeepMeter Lifetime Pro`
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Germany launch-price decision: €9.99 one-time / matching App Store Connect price point
- German Display Name: `KeepMeter Pro – Lifetime`
- German Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`
- English Display Name: `KeepMeter Pro Lifetime`
- English Description: `Unlimited active purchases. Pay once.`

`ci/storekit-metadata-preflight.py` hard-checks the exact product identity, required DE/EN copy and App Store Connect metadata-length limits before merge.

## App Store web URLs

Website source is prepared in `acciento89-bot/kamilunavo`, merge `afd809da2f814625b1cf45f6920c958897fb5398`:
- product-specific bilingual KeepMeter privacy page source: DONE
- KeepMeter added to shared Kamilunavo support page: DONE

Intended App Store Connect URLs **after live-deployment verification**:
- Privacy Policy: `https://kamilunavo.com/keepmeter/privacy`
- Support: `https://kamilunavo.com/support`

Source merge is not treated as proof that the public deployment is live. Both URLs remain release-open until verified against the deployed website.

## App Store Connect blockers

- [x] Lock operational v1 public app name / visual direction.
- [x] Add final AppIcon asset catalog and connect it to the target.
- [x] Add current v1 Privacy Manifest baseline and verify it in the built app bundle.
- [x] Lock exact Lifetime Pro product identity, DE/EN copy, reviewer notes and €9.99 launch-price decision in repo handoff.
- [x] Prepare KeepMeter-specific privacy-page source and shared support-page source on the Kamilunavo website.
- [ ] Verify KeepMeter privacy URL is live publicly.
- [ ] Verify Kamilunavo support URL is live publicly.
- [ ] Create/verify the App Store Connect app record with public name / bundle ID.
- [ ] Create the non-consumable Lifetime IAP with product ID `de.kamilunavo.keepmeter.pro.lifetime`.
- [ ] Configure €9.99 launch price / matching App Store price point and availability.
- [ ] Enter locked IAP display name/description/localizations and reviewer notes.
- [ ] Upload release-candidate Pro paywall review screenshot in App Store Connect.
- [ ] Complete App Privacy answers against the final binary.
- [ ] Capture final iPhone App Store screenshots from a release candidate.
- [ ] Perform signed Archive validation.
- [ ] Upload first TestFlight build.
- [ ] Exercise sandbox/TestFlight Lifetime purchase + entitlement + restore.
- [ ] Complete physical-device notification, persistence and VoiceOver QA before submission.

## Privacy / data behavior to preserve in listing

Current v1 product architecture is local-first:

- no account required
- no backend required for core purchase tracking
- no bank connection
- no inbox scraping
- purchase/usage records stored locally with SwiftData
- local return reminders use iOS notifications

App Store privacy declarations must be checked against the final binary and any later SDK additions before submission.

## German listing draft

### Name
KeepMeter

### Subtitle — draft
Behalten oder zurückgeben?

### Promotional text — draft
Tracke echte Nutzung, behalte Rückgabefristen im Blick und entscheide bewusster, welche Käufe wirklich bleiben sollen.

### Description — draft
Manche Käufe fühlen sich im Moment richtig an – und liegen kurze Zeit später unbenutzt herum. KeepMeter hilft dir, vor Ablauf der von dir eingetragenen Rückgabefrist bewusster zu entscheiden.

Füge einen Kauf hinzu, tracke mit einem Tippen jede echte Nutzung und beobachte, wie sich die Kosten pro Nutzung entwickeln. KeepMeter kombiniert deine Nutzungsdaten mit der verbleibenden Zeit und zeigt dir ein nachvollziehbares Signal zum Behalten, Prüfen oder Zurückgeben.

Funktionen in Version 1:
- Rückgabefristen für aktive Käufe im Blick behalten
- Nutzungen mit einem Tippen erfassen
- Kosten pro Nutzung automatisch berechnen
- nachvollziehbare BEHALTEN / PRÜFEN / ZURÜCK?-Signale
- lokale Erinnerungen vor dem eingetragenen Rückgabedatum
- abgeschlossene Käufe im Archiv
- kompakte Auswertungen
- lokale Datenspeicherung ohne Pflichtkonto

Kostenlos kannst du bis zu fünf aktive Käufe gleichzeitig tracken. Lifetime Pro schaltet unbegrenzt viele aktive Käufe mit einem einmaligen Kauf frei. Kein Abo.

Wichtig: KeepMeter verwendet das von dir eingetragene Rückgabedatum als Information für deine persönliche Entscheidung. Händlerbedingungen und gesetzliche Rechte können davon abweichen.

### Keywords — draft
kauf,rückgabe,rückgabefrist,shopping,kosten,nutzung,entscheidung,tracker,behalten,retoure

## English listing draft

### Name
KeepMeter

### Subtitle — draft
Keep it or return it?

### Promotional text — draft
Track real usage, keep return deadlines visible, and make more deliberate decisions about what is actually worth keeping.

### Description — draft
Some purchases feel right in the moment and end up barely used a short time later. KeepMeter helps you make a more deliberate decision before the return date you entered runs out.

Add a purchase, log every real use with one tap, and see how its cost per use develops. KeepMeter combines your usage with the remaining time and gives you an explainable signal to keep, review, or reconsider the purchase.

Version 1 includes:
- return-deadline tracking for active purchases
- one-tap usage logging
- automatic cost-per-use calculation
- explainable KEEP / REVIEW / RETURN? signals
- local reminders before the return date you entered
- archive for completed decisions
- lightweight insights
- local-first storage with no required account

The free version supports up to five active purchases at once. Lifetime Pro unlocks unlimited active purchases with a one-time purchase. No subscription.

Important: KeepMeter treats the return date you enter as information for your personal decision. Merchant policies and legal rights can differ.

### Keywords — draft
purchase,return,deadline,shopping,cost,usage,decision,tracker,keep,returns

## Screenshot capture plan

Automated CI produces representative runtime screenshots, but these are QA evidence rather than final App Store marketing screenshots.

Final App Store screenshot sequence:
1. populated Active dashboard with realistic purchases and different urgency states.
2. Purchase Detail showing usage count, cost/use and explainable decision signal.
3. Add Purchase emphasizing simple workflow and return deadline.
4. Insights showing tracked value, decisions and usage metrics.
5. Lifetime Pro showing one-time purchase / no subscription.

Use non-sensitive demo data and capture storefront-specific DE/EN screenshots if both localizations are published.

## Automated simulator runtime evidence

Gate 15 — PR #15 — workflow `32215165699` — merge `9c5b33bf0a0123afe243a0b32bd4d0139537cd82`:

- [x] real KeepMeter Debug app installed into a booted iPhone Simulator.
- [x] Light appearance + English onboarding launched.
- [x] Dark appearance + German dashboard launched.
- [x] app terminated and relaunched successfully.
- [x] runtime screenshots generated and uploaded.
- [x] screenshots visually inspected for obvious clipping/localization/contrast regression in those two states.
- [x] Release Simulator build passed after runtime gate.
- [x] built Release app contains matching `PrivacyInfo.xcprivacy`.

Gate 16 — centralized access policy — merge `14f265b4fee61d2be635cb2ba0ed15b994904924`:
- [x] one source of truth for the five-active-purchase Free threshold.
- [x] ProductRulesSmoke directly covers free-tier boundary and Pro bypass behavior.

A populated SwiftData relaunch/visual-signal gate is being validated separately and must not be marked complete until its final PR is green and visually reviewed.

## Runtime/device gates before first submission

Automated/simulator:
- [x] fresh Simulator install and onboarding render smoke.
- [x] app launch / terminate / relaunch lifecycle smoke.
- [x] representative Light appearance render.
- [x] representative Dark appearance render.
- [x] representative English localization render.
- [x] representative German localization render.
- [x] executable file-backed SwiftData reopen test.
- [x] DecisionEngine/product-rule automated coverage.
- [x] EN/DE key and format-placeholder parity.
- [x] Free/Pro access-policy boundary covered directly in automated product-rule tests.

Still required before submission:
- [ ] physical-device fresh install/onboarding pass.
- [ ] add a real test purchase on device and verify force-quit/relaunch persistence.
- [ ] log usage and verify relationship survives device relaunch.
- [ ] keep + return flows and archived read-only behavior on device.
- [ ] free limit blocks sixth active purchase in runtime interaction.
- [ ] Lifetime purchase unlocks unlimited active purchases.
- [ ] Restore re-establishes Lifetime entitlement.
- [ ] notification permission states interact correctly.
- [ ] at least one real local notification is delivered on device.
- [ ] broader Light/Dark all-important-screen inspection.
- [ ] Accessibility Dynamic Type spot-check on device.
- [ ] VoiceOver navigation pass.
- [ ] signed Release Archive succeeds.

## Current automated release evidence

Gate 11 — final AppIcon hard gate: GREEN.
Gate 12 — production StoreKit entitlement hardening: GREEN.
Gate 13 — product-rule + EN/DE localization regression gates: GREEN.
Gate 14 — Required Reason Privacy Manifest + built-bundle verification: GREEN.
Gate 15 — booted iPhone Simulator runtime + screenshots + relaunch: GREEN.
Gate 16 — centralized Free/Pro AccessPolicy + boundary tests: GREEN.

## Release rule

The automated Simulator pipeline is substantially stronger than a compile-only check, but it is still not a signed Archive, App Store sandbox session or physical-device validation. Do not mark KeepMeter release-ready until the App Store Connect Lifetime IAP, remaining device gates and first signed TestFlight archive/upload are complete.
