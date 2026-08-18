# KeepMeter — App Store Release Checklist

Last updated: 2026-08-18
Status: PRE-TESTFLIGHT / NOT READY TO SUBMIT

This file tracks App Store-facing release requirements. `docs/PROJECT_STATE.md` remains the authoritative overall project handoff.

## Locked technical values

- App target: `KeepMeter`
- Bundle ID: `de.kamilunavo.keepmeter`
- Current marketing version: `0.1.0`
- Current build number: `1`
- Deployment target: iOS 17.0+
- Device family: iPhone
- App category in target: Utilities
- StoreKit Lifetime product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Monetization: one-time non-consumable Lifetime Pro; no subscription in v1
- Free limit: 5 active purchases

## Public branding

- Working app name: `KeepMeter`
- Name status: PROVISIONAL — do not treat as legally cleared yet
- Final AppIcon: MISSING
- `Assets.xcassets/AppIcon.appiconset`: MISSING
- Public branding must not be locked until name/domain/trademark due diligence is sufficiently complete.

## App Store Connect blockers

- [ ] Lock public app name.
- [ ] Add final AppIcon asset catalog and connect it to the target.
- [ ] Create the app record with the final public name / bundle ID.
- [ ] Create the non-consumable Lifetime IAP with product ID `de.kamilunavo.keepmeter.pro.lifetime`.
- [ ] Choose final App Store price for Lifetime Pro; local StoreKit price 9.99 is test metadata only.
- [ ] Add IAP display name/description/localizations and review screenshot as required in App Store Connect.
- [ ] Supply privacy policy URL.
- [ ] Supply support URL.
- [ ] Complete App Privacy answers from actual app behavior.
- [ ] Capture final iPhone App Store screenshots from a release candidate.
- [ ] Perform signed Archive validation.
- [ ] Upload first TestFlight build.
- [ ] Exercise sandbox/TestFlight Lifetime purchase + entitlement + restore.
- [ ] Complete runtime notification, persistence, light/dark and VoiceOver QA before submission.

## Privacy / data behavior to preserve in listing

Current v1 product architecture is local-first:

- no account required
- no backend required for core purchase tracking
- no bank connection
- no inbox scraping
- purchase/usage records are stored locally with SwiftData
- local return reminders use iOS notifications

App Store privacy declarations must be checked against the final binary and any later analytics/crash SDKs before submission. Do not infer final App Privacy answers from this draft if the implementation changes.

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
- nachvollziehbare KEEP / REVIEW / RETURN?-Signale
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

Do not capture final store screenshots until the visual identity and AppIcon are locked and the runtime pass is green.

Suggested sequence:

1. Active dashboard with at least two realistic purchases and different urgency states.
2. Purchase detail showing usage count, cost per use and explainable decision signal.
3. Add Purchase screen emphasizing the simple workflow and return deadline.
4. Insights showing tracked value, decisions and usage metrics.
5. Lifetime Pro screen showing one-time purchase / no subscription.

Screenshots must use non-sensitive demo data and should be captured separately for DE and EN if both storefront localizations are published.

## Runtime gates before first submission

- [ ] Fresh install / onboarding.
- [ ] Add purchase and verify it survives force-quit/relaunch on device.
- [ ] Log usage and verify relationship survives relaunch.
- [ ] Keep and return flows; archived items stay read-only.
- [ ] Free limit blocks sixth active purchase.
- [ ] Lifetime purchase unlocks unlimited active purchases.
- [ ] Restore re-establishes Lifetime entitlement.
- [ ] Notification permission states behave correctly.
- [ ] At least one real local notification is delivered on device.
- [ ] Light appearance inspection.
- [ ] Dark appearance inspection.
- [ ] Accessibility Dynamic Type inspection.
- [ ] VoiceOver navigation pass.
- [ ] Signed Release archive succeeds.

## Release rule

A green Debug/Release simulator CI build is necessary but not sufficient for TestFlight/App Store readiness. Do not mark the app release-ready until the final AppIcon/branding, App Store Connect IAP, signed archive and runtime device gates above are complete.
