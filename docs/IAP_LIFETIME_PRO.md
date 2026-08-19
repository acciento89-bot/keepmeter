# KeepMeter — Lifetime Pro App Store Connect Handoff

Last updated: 2026-08-19
Status: READY FOR APP STORE CONNECT ENTRY / REVIEW SCREENSHOT STILL REQUIRED

This file is the single handoff for creating KeepMeter's v1 non-consumable In-App Purchase in App Store Connect.

## Locked product

- Type: **Non-Consumable**
- Reference Name: `KeepMeter Lifetime Pro`
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Launch pricing decision: **€9.99 one-time in Germany**; select the matching App Store Connect price point/equivalent regional pricing.
- Subscription: **none**
- Family Sharing: off for v1

The Product ID is already used by the app's StoreKit 2 implementation and local StoreKit test configuration. Do not create a different identifier.

## Localized customer metadata

These strings intentionally fit App Store Connect's current In-App Purchase limits: Display Name 2–30 characters, Description max 45 characters.

### German (Germany)

- Display Name: `KeepMeter Pro – Lifetime`
- Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`

### English (U.S.)

- Display Name: `KeepMeter Pro Lifetime`
- Description: `Unlimited active purchases. Pay once.`

`ci/storekit-metadata-preflight.py` enforces the limits and exact v1 product identity against `KeepMeter/StoreKit/KeepMeter.storekit`.

## App Review information

### Review Notes

Use this reviewer-facing text:

> KeepMeter Lifetime Pro is a one-time Non-Consumable In-App Purchase. It is not a subscription and no account or test credentials are required. To open the purchase screen, open the Settings tab and tap the KeepMeter Pro card. The purchase unlocks unlimited active purchase tracking; the free version supports up to five active purchases. Restore Purchases is available both on the Pro purchase screen and in Settings. Product ID: de.kamilunavo.keepmeter.pro.lifetime. Core purchase and usage records are stored locally on the device.

### App Review Screenshot

Required before IAP submission.

Capture a release-candidate iPhone screenshot that clearly shows the KeepMeter Pro paywall, including:
- `KeepMeter Pro`
- `Unlimited active purchases`
- `No subscription`
- the StoreKit-provided purchase price/button
- `Restore purchases`

Do not use the DEBUG StoreKit QA section in the reviewer screenshot.

## Reviewer path verified from v1 UI source

Primary path:
1. Open **Settings**.
2. Tap the **KeepMeter Pro** card at the top.
3. The Pro paywall opens.
4. The purchase button uses the price returned by StoreKit.
5. Restore Purchases is available on the paywall and in Settings.

Alternative free-limit path:
1. Have five active purchases while not Pro.
2. Tap the Add Purchase `+` button.
3. KeepMeter routes to the Pro paywall instead of allowing a sixth active purchase.

## App Store web URLs

The source for KeepMeter's public privacy page and the shared Kamilunavo support page is now merged in `acciento89-bot/kamilunavo` (website merge `afd809da2f814625b1cf45f6920c958897fb5398`).

Intended App Store Connect values after live-deployment verification:
- Privacy Policy URL: `https://kamilunavo.com/keepmeter/privacy`
- Support URL: `https://kamilunavo.com/support`

Do **not** mark either URL as production-verified merely because the website source is merged. Confirm both return the intended live pages before entering them into the final release checklist.

## App Store Connect entry checklist

- [ ] App record exists for bundle ID `de.kamilunavo.keepmeter`.
- [ ] Create In-App Purchase -> **Non-Consumable**.
- [ ] Enter Reference Name exactly `KeepMeter Lifetime Pro`.
- [ ] Enter Product ID exactly `de.kamilunavo.keepmeter.pro.lifetime`.
- [ ] Configure availability.
- [ ] Configure €9.99 launch price / matching App Store price point.
- [ ] Add German localization exactly as above.
- [ ] Add English localization exactly as above.
- [ ] Add Review Notes from this file.
- [ ] Upload release-candidate Pro paywall screenshot for App Review.
- [ ] Verify KeepMeter privacy URL is live.
- [ ] Verify Kamilunavo support URL is live.
- [ ] Save and verify the product becomes available to sandbox/TestFlight StoreKit.
- [ ] Run sandbox/TestFlight purchase + entitlement + restore before App Store submission.

## Important boundaries

- The local `.storekit` price is test metadata; App Store Connect remains authoritative for production price/availability.
- Do not convert Lifetime Pro into an auto-renewable subscription for v1.
- Do not change the product ID after creating it in App Store Connect.
- Do not claim Lifetime Pro includes unspecified future features; the current benefit is unlimited active purchase tracking with a one-time purchase.
