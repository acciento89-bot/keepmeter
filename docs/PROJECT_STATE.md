# KeepMeter — Project State

Last updated: 2026-08-19
Status: ACTIVE — POPULATED SIMULATOR PERSISTENCE + VISUAL RUNTIME GREEN / APPLE + PHYSICAL-DEVICE QA OPEN
Repository: `acciento89-bot/keepmeter`
Default branch: `main`
Current verified product checkpoint: `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6`

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
- Gate 17 seeds deterministic purchases into the **real running iOS Simulator app**, terminates/relaunches without reseeding and verifies the same SwiftData IDs, prices, usage counts, outcomes and DecisionEngine results through an in-app DEBUG probe.
- Gate 17 therefore proves populated Simulator persistence across app lifecycle, not merely standalone model-container reopening.

Still open:
- equivalent force-quit/relaunch check on a physical iPhone.

## StoreKit / Lifetime Pro

Product ID: `de.kamilunavo.keepmeter.pro.lifetime`.

Implemented/hardened:
- local `KeepMeter/StoreKit/KeepMeter.storekit` NonConsumable test product.
- shared Debug scheme references local StoreKit config.
- DEBUG Settings diagnostics for product/price/entitlement.
- `Transaction.currentEntitlements` refreshes independently of product-metadata loading.
- verified `Transaction.updates` and `Transaction.unfinished` handled.
- access refresh occurs before `transaction.finish()`.
- unverified transactions never unlock Pro.
- `AppStore.sync()` only behind explicit Restore Purchases.

In progress in PR #18:
- App Store-compatible exact DE/EN Lifetime Pro copy.
- €9.99 Germany launch-price decision / matching App Store price point.
- IAP metadata-length/identity preflight.
- reviewer notes/path/review-screenshot handoff.
- App Store listing field-limit preflight.
- App Privacy handoff.

Still open:
- interactive local Free -> Pro -> Restore session.
- matching App Store Connect Lifetime IAP creation/configuration.
- sandbox/TestFlight purchase + restore session.

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

Gate 17 runtime visual evidence:
- fresh English/Light onboarding: clean.
- populated English/Light dashboard: clean; deterministic KEEP and RETURN? purchases visible.
- persisted German/Dark dashboard after terminate/relaunch: clean, localized and data-preserving.
- all three screenshots manually inspected after final workflow.
- automated native `ci/RuntimeScreenshotSignal.swift` rejects black/near-uniform screenshots so a visual blank cannot pass merely because a PNG exists.

Still open:
- broader all-important-screen physical-device Light/Dark review.
- physical/runtime VoiceOver pass.
- physical Dynamic Type spot-check.

## Runtime CI hardening

Runner: `macos-26-intel`.

Gate 17 added:
- DEBUG-only deterministic purchase seeding.
- DEBUG-only persistence verification sentinel.
- unique per-launch DEBUG token.
- launch proof is written only once the SwiftUI scene is actually `.active`.
- bounded foreground nudge for hosted CoreSimulator launch-client flakiness.
- visual-signal validation for every runtime screenshot.
- Release binary scan that rejects every DEBUG runtime token, sentinel name and seeded demo value.

No Gate 17 QA hooks are permitted in the Release binary.

## Privacy

`KeepMeter/PrivacyInfo.xcprivacy` is bundled and CI-gated.

Current v1 baseline:
- `NSPrivacyTracking = false`.
- no tracking domains.
- no collected-data types for current local-only core.
- UserDefaults Required Reason `CA92.1`.
- Release bundle manifest must plist-match source.

PR #18 prepares `docs/APP_PRIVACY_HANDOFF.md`; final App Store privacy answers must still be rechecked against the actual release-candidate binary.

## Brand / assets

- operational v1 public name: **KeepMeter**; not claimed as formal trademark clearance.
- primary blue approx. `#306BF5`, soft blue approx. `#63A1FF`; green reserved for positive/KEEP meaning.
- final custom decision-meter/gauge AppIcon is 1024×1024, opaque/no alpha and hard CI-gated.

## Website / public release pages

Kamilunavo website source merge `afd809da2f814625b1cf45f6920c958897fb5398` added:
- bilingual KeepMeter-specific privacy page source.
- KeepMeter to shared Kamilunavo support page.

Intended App Store URLs after live-deployment verification:
- `https://kamilunavo.com/keepmeter/privacy`
- `https://kamilunavo.com/support`

Source merge is **not** treated as proof that those pages are live. Public deployment verification remains open.

## Verified gates

1. PR #1 — Functional MVP — workflow `32178808223` — merge `bf024336455d2a65da1e7d5f25ac87f142a3de8d` — GREEN.
2. PR #2 — Visual polish — workflow `32179763750` — merge `45c53308ae41fc38eec5049c0181d4b0d7ede42b` — GREEN.
3. PR #3 — StoreKit/reminder hardening — workflow `32182015862` — merge `0ec1e7b87fb3148462fcdc923770684e9bf67f1f` — GREEN.
4. PR #4 — Notification QA controls — workflow `32182418696` — merge `e82813b2f53677112700c5f0cdbcb0db6a9402c7` — GREEN.
5. PR #5 — Local StoreKit environment — workflow `32184529919` — merge `f9541c26a4ea63b78c302977a95566827c37b45f` — GREEN.
6. PR #6 — Data integrity/accessibility — workflow `32185398795` — merge `f3718152acbd7b51ba90bbb399e3de6fc1116d64` — GREEN.
7. PR #7 — File-backed SwiftData reopen — workflow `32186180485` — merge `2b93368f084ccf4808a0fa2a5e68c5d7dc51bc0c` — GREEN.
8. PR #8 — Release compile — workflow `32186439191` — merge `dad79a620f375ed2c5eaa9ce4d40784130aab164` — GREEN.
9. PR #9 — App Store release preflight — workflow `32186964254` — merge `5582461de995c8954f44b78c3314b3dbf2ee22c2` — GREEN.
10. PR #10 — v1 brand lock — workflow `32187367731` — merge `eaadd52c37ce38e98e3ad96a55bda4eaea84291a` — GREEN.
11. PR #11 — Final AppIcon hard gate — workflow `32189137123` — merge `cedc90a883713683217f663485a6d8f2e09fd63a` — GREEN.
12. PR #12 — Production StoreKit entitlement recovery — workflow `32189569075` — merge `56f501c4f220032ba5fb3ab88dd409b94c5524b6` — GREEN.
13. PR #13 — Product rules + localization — workflow `32212716880` — merge `fe88224b38011d25934b49a1edb2fc2030425306` — GREEN.
14. PR #14 — Required-reason Privacy Manifest — workflow `32212975137` — merge `223eb041a0e4f306fd5dc0c5ed29deb7f12cd197` — GREEN.
15. PR #15 — Booted Simulator runtime + screenshots + relaunch — workflow `32215165699` — merge `9c5b33bf0a0123afe243a0b32bd4d0139537cd82` — GREEN.
16. PR #16 — Central Free/Pro AccessPolicy — workflow `32216276685` — merge `14f265b4fee61d2be635cb2ba0ed15b994904924` — GREEN.
17. PR #17 — Populated Simulator persistence + active-scene launch proof + visual-signal screenshots + Release QA isolation — workflow `32249500834` — merge `43e353fefd9b41f0d777ee2fcd475e7c62eef3b6` — GREEN and final screenshots manually inspected.

Major product/source/design passes must remain CI-green before merge/TestFlight.

## Release status

DONE / automated:
- functional/visual Debug + Release builds.
- AppIcon.
- Privacy Manifest.
- DecisionEngine / AccessPolicy / EN-DE regression tests.
- file-backed SwiftData reopen.
- booted Simulator lifecycle.
- populated Simulator SwiftData persistence across terminate/relaunch.
- representative Light/EN and Dark/DE runtime visuals with anti-black-screen gate.
- DEBUG QA isolation from Release binary.

OPEN:
- PR #18 App Store/IAP metadata hardening must be rebased/synced onto Gate 17 and pass full CI.
- live verification of public support/privacy URLs.
- App Store Connect app record + Lifetime IAP.
- interactive StoreKit purchase/restore.
- physical-device persistence/notification/VoiceOver/Dynamic Type checks.
- signed Release Archive.
- first TestFlight upload.
- sandbox/TestFlight Lifetime Pro purchase + restore.

No TestFlight build has been uploaded yet.

## Immediate next steps

1. Sync PR #18 onto Gate 17, preserving the hardened runtime/visual/Release-isolation pipeline, then make it fully green and merge.
2. Verify/deploy public KeepMeter privacy/support pages.
3. Create/configure the matching App Store Connect Lifetime IAP and app record when authenticated Apple-side access is available.
4. Automate or exercise local StoreKit Free -> Pro -> restore where possible.
5. Perform physical-device notification/persistence/accessibility gates.
6. Only then create the first signed TestFlight build; do not burn intermediate TestFlight build numbers.
