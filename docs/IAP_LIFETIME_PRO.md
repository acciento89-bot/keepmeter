# KeepMeter — Lifetime Pro App Store Connect Handoff

Last updated: 2026-08-19
Status: READY FOR APP STORE CONNECT ENTRY / REVIEW SCREENSHOT + APPLE-SIDE CREATION STILL REQUIRED

This file is the human handoff for creating KeepMeter's v1 non-consumable In-App Purchase in App Store Connect.

Machine-readable mirror: `metadata/AppStoreConnectSetup.json`.
Operational Apple-side order: `docs/APP_STORE_CONNECT_RUNBOOK.md`.

## Locked product

- Type: **Non-Consumable**
- Reference Name: `KeepMeter Lifetime Pro`
- Product ID: `de.kamilunavo.keepmeter.pro.lifetime`
- Launch pricing decision: **€9.99 one-time in Germany**; select the matching current App Store Connect price point/equivalent regional pricing.
- Subscription: **none**
- Family Sharing: off for v1

The Product ID is already used by the app's StoreKit 2 implementation, local StoreKit configuration and required StoreKitTest/XCTest. Do not create a different identifier.

Apple does not allow the Product ID or purchase type to be changed after creation. Treat the first App Store Connect entry as permanent identity setup.

## Localized customer metadata

These strings intentionally fit Apple's current In-App Purchase metadata limits: Display Name 2–30 characters; Description maximum 45 characters. At least one localization is required; KeepMeter prepares both German and English.

### German (Germany)

- Display Name: `KeepMeter Pro – Lifetime`
- Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`

### English (U.S.)

- Display Name: `KeepMeter Pro Lifetime`
- Description: `Unlimited active purchases. Pay once.`

`ci/storekit-metadata-preflight.py` enforces the limits and exact v1 product identity against `KeepMeter/StoreKit/KeepMeter.storekit`.
`ci/app-store-connect-handoff-preflight.py` cross-checks the same identity against `metadata/AppStoreConnectSetup.json`.

## App Review information

Apple's current IAP setup requires App Review information for the product. KeepMeter must provide both the reviewer notes and the release-candidate review screenshot before the IAP is ready for review.

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

The App Review screenshot is for Apple's review process; it is not the public App Store screenshot set.

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

## Required StoreKit evidence already in repository CI

Gate #21 proves on Xcode 26.2 / iOS 26.2:
- initial Free state;
- real `SKTestSession` Lifetime transaction;
- production `EntitlementStore` unlocks Pro;
- entitlement is recovered by a newly-created store;
- entitlement disappears after the StoreKitTest transaction is cleared;
- StoreKit job is required CI, not `continue-on-error`.

This does **not** replace the real App Store sandbox/TestFlight gate. After the first TestFlight build, KeepMeter must still prove the Apple-hosted product, purchase, entitlement persistence and explicit `AppStore.sync()` Restore Purchases path.

## App Store web URLs

Prepared App Store Connect values after live-deployment verification:
- Privacy Policy URL: `https://kamilunavo.com/keepmeter/privacy`
- Support URL: `https://kamilunavo.com/support`

Website source history:
- initial KeepMeter privacy/support source merge: `afd809da2f814625b1cf45f6920c958897fb5398`
- support contact hardening merge: `6cf96be83b29e74ad5414cc02e4997d3508e6f57`

The support source now directly includes `support@kamilunavo.com`, the existing operator/business address and a link to the full imprint. Do **not** mark either URL production-verified merely because source is merged. Confirm the deployed pages live over HTTPS first.

## App Store Connect entry checklist

- [ ] App record exists for bundle ID `de.kamilunavo.keepmeter` and locked SKU `keepmeter-ios-001`.
- [ ] Create In-App Purchase -> **Non-Consumable**.
- [ ] Enter Reference Name exactly `KeepMeter Lifetime Pro`.
- [ ] Enter Product ID exactly `de.kamilunavo.keepmeter.pro.lifetime`.
- [ ] Configure availability.
- [ ] Configure €9.99 launch price / matching current App Store price point.
- [ ] Keep Family Sharing off for v1.
- [ ] Add German localization exactly as above.
- [ ] Add English localization exactly as above.
- [ ] Add Review Notes from this file.
- [ ] Upload release-candidate Pro paywall screenshot for App Review.
- [ ] Verify KeepMeter privacy URL is live.
- [ ] Verify Kamilunavo support URL is live.
- [ ] Save and verify the product becomes available to sandbox/TestFlight StoreKit.
- [ ] Run sandbox/TestFlight purchase + entitlement + explicit Restore Purchases before App Store submission.

Apple notes that IAP metadata changes can take time to propagate to the sandbox; allow up to roughly one hour before treating a just-edited product as missing/broken.

## Important boundaries

- The local `.storekit` price is test metadata; App Store Connect remains authoritative for production price/availability.
- Do not convert Lifetime Pro into an auto-renewable subscription for v1.
- Do not change the product ID or purchase type after creating the product.
- Do not claim Lifetime Pro includes unspecified future features; the current benefit is unlimited active purchase tracking with a one-time purchase.
- Do not treat local StoreKitTest success as proof that the App Store Connect product itself is correctly configured; the sandbox/TestFlight gate remains mandatory.
