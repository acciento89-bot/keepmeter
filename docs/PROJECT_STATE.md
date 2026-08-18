# KeepMeter — Project State

Last updated: 2026-08-18
Status: ACTIVE — IMPLEMENTATION STARTED
Repository: `acciento89-bot/keepmeter`

## Product thesis

KeepMeter answers one focused question:

> Is this purchase actually worth keeping before the return window closes?

Core loop:

**Bought -> Use -> Measure -> Decide before deadline.**

## Locked MVP

1. Add a purchase with name, price, purchase date and return deadline.
2. Show active purchases ordered by urgency.
3. Log a usage with one tap.
4. Calculate cost per use.
5. Show days remaining in the return window.
6. Produce an explainable KEEP / REVIEW / RETURN recommendation.
7. Schedule local return-deadline reminders.
8. Archive purchases as kept or returned.
9. German + English architecture from the first build.
10. Free tier: up to 5 active purchases.
11. Lifetime Pro unlock via StoreKit 2; no subscription in v1.

## Native stack

- SwiftUI
- SwiftData
- UserNotifications
- StoreKit 2
- iOS 17+

## Decision-engine v1

The recommendation is deliberately transparent, not AI-generated.

Signals:
- usage count
- cost per use
- percentage of return window elapsed
- time since last use

Rules are conservative: the app may suggest review/return, but the UI must explain why and never pretend to know the user's personal value better than the user.

## Guardrails

- No account/backend for core v1.
- No bank connection.
- No inbox scraping.
- No generic receipt/warranty-vault positioning.
- No forced subscription.
- No opaque AI recommendation.
- No legal claim that a displayed return date is legally guaranteed; user confirms the merchant-specific deadline.

## Current implementation state

- Repository initialized.
- README added.
- SwiftUI source scaffold underway.
- SwiftData models underway.
- Dashboard, add-purchase and detail screens underway.
- Decision engine underway.
- Local notification service underway.
- Xcode project configuration still to be added/validated.
- StoreKit product configuration not yet created.
- App icon / visual identity not yet locked.
- Working product name `KeepMeter` remains provisional pending final naming/trademark/domain due diligence.

## Next steps

1. Complete the initial native source scaffold.
2. Add Xcode project configuration and compile validation.
3. Add German/English localization resources.
4. Add Lifetime Pro StoreKit plumbing.
5. Add first-pass visual system and app icon direction.
6. Run simulator/device QA.
7. Prepare first TestFlight build when implementation is stable enough.

## Cross-project handoff

The master App Factory status lives in `acciento89-bot/appideenchatgpt/docs/APP_FACTORY_STATE.md` and must be updated after every major KeepMeter pass.
