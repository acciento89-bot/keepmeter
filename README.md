# KeepMeter

KeepMeter is App Factory #001: a local-first iPhone utility that helps people decide whether a recent purchase is worth keeping before the return window closes.

## Core loop

**Bought -> Use -> Measure -> Decide before deadline.**

The app combines:
- purchase price
- actual usage count
- cost per use
- return deadline
- an explainable KEEP / REVIEW / RETURN recommendation

## Current MVP surface

- 3-step onboarding
- active-purchase dashboard
- add-purchase flow
- one-tap usage logging
- explainable decision detail
- archive for kept/returned purchases
- lightweight insights dashboard
- Settings / Pro management
- local return-deadline reminders
- German + English localization

## Product principles

- Native SwiftUI
- SwiftData persistence
- No account/backend for the core experience
- Local notifications for return deadlines
- German + English from the first release
- Freemium with a one-time Lifetime Pro unlock
- No forced subscription

See `docs/PROJECT_STATE.md` for the authoritative implementation state.
