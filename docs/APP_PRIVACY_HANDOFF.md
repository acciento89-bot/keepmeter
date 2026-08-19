# KeepMeter — App Store Privacy Handoff

Last updated: 2026-08-19
Status: V1 ANSWERS PREPARED / REVERIFY AGAINST RELEASE-CANDIDATE BINARY BEFORE SUBMISSION

This file records the intended App Store Connect privacy answers for the current KeepMeter v1 implementation. It is a release handoff, not a substitute for checking the final binary and Apple questionnaire at submission time.

## Current v1 architecture audited

KeepMeter currently:
- has no required account or sign-in;
- has no Kamilunavo backend for core app data;
- stores entered purchase/usage records locally with SwiftData;
- stores app-local preferences locally with UserDefaults / `@AppStorage`;
- schedules local notifications through iOS;
- uses StoreKit 2 for the one-time Lifetime Pro purchase and entitlement state;
- contains no third-party analytics SDK;
- contains no advertising SDK;
- performs no cross-app tracking;
- does not upload purchase names, merchants, prices, dates, usage events, notification data or device identifiers to Kamilunavo.

Apple defines App Store privacy-label “collection” as transmitting data off the device in a way that lets the developer and/or third-party partners access it for longer than needed to service a real-time request. Under that definition, KeepMeter's current locally stored purchase/usage records are not developer-collected data.

Apple also states that payment information does not need to be disclosed when a payment service handles the payment outside the app and the developer never has access to the payment information. KeepMeter uses Apple's StoreKit flow and does not receive full payment-card details.

## Intended App Store Connect answer for current v1

### Data Collection

**Data Not Collected**

For the current v1 binary, do not select App Privacy data types merely because the same information exists locally on the user's device. The current app does not transmit those records to Kamilunavo or an integrated third-party partner.

### Tracking

**No**

- no ATT tracking flow required for current v1;
- no cross-app/web tracking;
- no advertising identifiers;
- no advertising network SDK.

### Privacy Policy URL

Intended value after live verification:
`https://kamilunavo.com/keepmeter/privacy`

Website source is already prepared/merged, but live deployment must be verified before the URL is treated as release-ready.

### User Privacy Choices URL

Optional for current v1. No account/server-side user dataset exists to manage. Do not invent a privacy-choices workflow solely to populate this optional field.

## What does NOT currently require a collected-data disclosure

Subject to the final-binary recheck:
- locally stored purchase names / optional merchant names;
- locally stored prices and dates;
- locally stored usage events;
- locally stored onboarding/settings preferences;
- local-notification scheduling state;
- Apple-handled payment-card information that Kamilunavo does not receive.

## Re-audit triggers — STOP before release if any are added

The `Data Not Collected` answer is no longer automatically valid if the release candidate adds any of the following:
- analytics or telemetry SDKs;
- crash-reporting SDKs that transmit diagnostics to Kamilunavo/a third party;
- a backend/account system;
- cloud sync;
- remote notification/push-token collection;
- receipt, purchase or usage uploads to a server;
- ad SDKs or attribution SDKs;
- device/user identifiers sent off-device;
- remote AI/OCR processing;
- embedded web flows that collect app-originating user data.

If any trigger is introduced, re-audit every transmitted field and its purpose/linkage/tracking status before App Store submission.

## Release checklist

- [ ] Verify final Release target has no analytics/ad/network data collection added after this handoff.
- [ ] Verify `PrivacyInfo.xcprivacy` still matches actual Required Reason APIs and SDK manifests.
- [ ] Verify public KeepMeter privacy-policy URL is live.
- [ ] In App Store Connect, answer current v1 as **Data Not Collected** only if the final binary still matches this architecture.
- [ ] Confirm Tracking = **No**.
- [ ] Preview the resulting App Privacy product-page section before submission.

## Source-of-truth rule

If this file, the privacy manifest, the privacy webpage and the actual release binary disagree, **the release must stop until all four are reconciled**. The actual binary behavior is authoritative.
