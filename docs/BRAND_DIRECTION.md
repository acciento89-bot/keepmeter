# KeepMeter — v1 Brand Direction

Last updated: 2026-08-18
Status: V1 OPERATIONAL BRAND LOCK

This document locks the visual direction for KeepMeter v1 so the AppIcon, screenshots and store listing do not drift into unrelated styles. This is a product/design lock, not a legal trademark opinion.

## Name

Public working brand for v1: **KeepMeter**

Decision: proceed with KeepMeter for v1 production design and App Store preparation unless a later authoritative trademark/domain check reveals a concrete conflict.

Reasoning:
- the name directly supports the product thesis: measure whether a purchase earns being kept
- it is short enough for app/UI use
- current exact-name web/app searches did not surface an obvious same-name consumer app/software product in the searches performed
- this does **not** replace a professional clearance search or guarantee registrability

## Product promise

> Measure whether a purchase earns being kept before the return window closes.

Short consumer framing:

**Keep it or return it? Know before the deadline.**

German:

**Behalten oder zurückgeben? Entscheide vor der Frist.**

## Brand personality

KeepMeter should feel:
- precise, not financial
- calm, not alarmist
- premium-native iOS, not SaaS-dashboard-like
- decision-oriented, not shopping-addictive
- trustworthy and explainable, not AI-magical
- clean enough to work in light and dark appearance

Avoid:
- shopping-cart imagery as the main identity
- receipt/document-vault aesthetics
- red-heavy urgency branding
- coins, bank symbols or finance-app cues
- generic sparkle/AI imagery
- literal text or a `K` monogram as the primary app icon
- excessive gradients, gloss or pseudo-3D decoration

## Locked palette

The app's existing semantic colors remain the source of truth.

Primary accent:
- RGB: 0.19 / 0.42 / 0.96
- approximate sRGB: #306BF5

Accent soft:
- RGB: 0.39 / 0.63 / 1.00
- approximate sRGB: #63A1FF

Success:
- RGB: 0.13 / 0.66 / 0.43
- approximate sRGB: #21A86E

Warning:
- RGB: 0.95 / 0.58 / 0.12
- approximate sRGB: #F2941F

Danger:
- RGB: 0.92 / 0.27 / 0.31
- approximate sRGB: #EB454F

The AppIcon should be dominated by the primary blue family. Green may be used only as a small positive/decision accent, not as a 50/50 second brand color.

## AppIcon concept — locked direction

### Core symbol

A **minimal decision meter**:
- circular or partial-circular gauge / meter arc
- one clear needle or indicator
- a subtle positive check/decision cue integrated into the meter geometry rather than pasted beside it
- no text
- no tiny labels, ticks or numbers
- no literal shopping bag required

The symbol should communicate **measure -> decide**, which is more ownable for KeepMeter than a generic cart/bag/receipt.

### Composition

- single centered symbol
- generous negative space
- strong silhouette readable at 29–60 px
- balanced enough for iOS rounded-square masking
- no border touching the icon edge
- no thin strokes that disappear at small sizes

### Background

Preferred:
- deep/primary KeepMeter blue base
- restrained transition toward the softer blue to create depth
- avoid rainbow/multicolor gradients

### Foreground

Preferred:
- near-white meter geometry
- optional small KeepMeter-success green accent for the final check/indicator state
- high contrast in both standard and tinted-icon contexts

## AppIcon acceptance tests

The final icon must pass all of these before it is committed:

1. Recognizable at approximately 29 px without reading text.
2. Still visually balanced at 1024 px without unnecessary detail.
3. Does not resemble a bank, crypto, speedometer/car, fitness tracker or generic shopping cart at first glance.
4. Meter/decision concept is visible in silhouette.
5. Works without a surrounding outline.
6. Does not depend on transparency; final App Store icon must have an opaque background.
7. No text, letters or wordmark inside the icon.
8. Matches the in-app KeepMeter blue family.
9. Works on both light and dark home screens.
10. Looks like a first-party-quality iOS utility rather than a template icon.

## In-app identity

Continue using:
- system typography
- rounded native-feeling cards
- blue primary actions
- green only for KEEP/success
- orange for review/attention
- red for return candidate/destructive meaning
- SF Symbols inside the app where appropriate

The AppIcon itself should be custom artwork; it must not simply export an SF Symbol on a blue square.

## Store visual direction

Screenshots should use the same blue-dominant identity and show the product loop, not decorative marketing scenes.

Primary screenshot story:
1. Add a purchase.
2. Track real use.
3. See cost per use + deadline.
4. Get an explainable decision signal.
5. Keep or return in time.

Screenshot copy should remain short enough that the live UI is the hero.

## Legal / naming caveat

The v1 brand lock is operational. The exact-name searches performed on 2026-08-18 did not reveal an obvious same-name consumer app/software result, but search-engine results are not a complete trademark clearance. EUIPO recommends searching identical and similar marks, including relevant goods/services, in TMview/eSearch. If a later authoritative search reveals a material conflict, the public brand must be revisited before App Store submission.

## Next implementation step

Create the final 1024x1024 AppIcon artwork from this direction, add `KeepMeter/Assets.xcassets/AppIcon.appiconset`, wire `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` for Debug and Release, then convert the current CI AppIcon warning into a hard release-preflight failure.
