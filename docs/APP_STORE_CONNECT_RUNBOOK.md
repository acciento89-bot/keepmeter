# KeepMeter — App Store Connect Runbook

Last updated: 2026-08-19
Status: REPOSITORY HANDOFF READY / APPLE-SIDE ENTRY + LIVE URL + DEVICE GATES OPEN

This is the exact operational order for taking KeepMeter from the repository-approved Gate #22 state to the first TestFlight build and then App Review.

Machine-readable source of truth for values entered into App Store Connect: `metadata/AppStoreConnectSetup.json`.
App Store listing copy source: `metadata/AppStoreListing.json`.
Lifetime IAP copy/reviewer source: `docs/IAP_LIFETIME_PRO.md`.
Overall project state: `docs/PROJECT_STATE.md`.

## 0. Do not upload yet

The guarded workflow `.github/workflows/testflight.yml` exists, but its first dispatch remains intentionally blocked by release policy until the Apple-side record, live web URLs, repository credentials and physical-device preflight are ready.

No normal CI run can upload to TestFlight.

## 1. Apple account / Business prerequisites

Before creating or submitting the app:

- ensure the current Apple agreements are accepted;
- verify the App Store Connect account can create an iOS app record;
- verify the account-level EU Digital Services Act trader-status declaration is complete;
- verify KeepMeter's app-specific DSA setting is consistent with the account/distribution decision;
- if distribution in the EU uses trader status, make sure Apple's required display contact details are verified in App Store Connect;
- do not infer or change trader status from this repository — it is an Apple-account/legal self-assessment gate.

Apple currently requires a DSA trader-status declaration even for accounts that do not distribute in the EU; EU trader distribution requires verified contact details. KeepMeter has a paid Lifetime IAP, which is one of the commercial factors Apple lists for the trader self-assessment.

## 2. Create the App Store Connect app record

Apps -> `+` -> **New App**.

Enter:

- Platform: **iOS**
- Name: **KeepMeter**
- Primary language: **German**
- Bundle ID: **`de.kamilunavo.keepmeter`**
- SKU: **`keepmeter-ios-001`**
- User Access: follow the existing Kamilunavo team-access policy; this is an account permission choice, not a product identity field.

Important:

- Apple requires the app record before a build can be uploaded.
- The SKU is internal/not customer-visible and cannot be changed after the app is added to the account.
- The Bundle ID must match the Xcode project. Do not create a second KeepMeter Bundle ID.

## 3. App Information / commercial setup

Lock these product choices:

- Primary category: **Utilities**
- App base price: **Free**
- Monetization: **one Non-Consumable Lifetime Pro IAP**
- Version: **0.1.0**
- First build: **1**
- iPhone / iOS 17+

Complete the current App Store Connect-required account/app declarations, including age rating and content-rights questions, against the actual final app. Do not copy guessed answers from old chats.

For export-compliance/encryption questions, answer against the final binary. Current KeepMeter product scope does not intentionally add a custom encryption feature, but this repository does not pre-authorize a legal/export-compliance answer.

## 4. Public URLs

Prepared values:

- Privacy Policy URL: `https://kamilunavo.com/keepmeter/privacy`
- Support URL: `https://kamilunavo.com/support`

Do not mark either URL ready until both are live and show the intended page over HTTPS.

Apple currently requires a Privacy Policy URL for iOS apps. The Support URL is App Store-facing and should lead to real contact information. Kamilunavo website source now includes direct support email, operator/business address and an imprint link on `/support`; live deployment still has to be verified.

## 5. App Privacy

Current audited v1 handoff:

- Data Collected: **No**
- Tracking: **No**
- Privacy Policy URL: `https://kamilunavo.com/keepmeter/privacy`

Before submission, re-audit the actual release-candidate binary. Any analytics/crash SDK, backend, cloud sync, ads, push-token collection, remote AI/OCR or other off-device collection invalidates the current handoff until reviewed.

Apple requires the App Privacy responses to include the app's own practices and those of integrated third-party partners.

## 6. App Store listing localizations

Create/verify:

- German (`de-DE`) — primary
- English (U.S.) (`en-US`)

Copy name, subtitle, promotional text, description and keywords directly from `metadata/AppStoreListing.json`.

Do not retype from chat history. Required field limits are enforced by `ci/app-store-listing-preflight.py`.

## 7. Create Lifetime Pro

Apps -> KeepMeter -> Monetization -> In-App Purchases -> `+`.

Create exactly:

- Type: **Non-Consumable**
- Reference Name: **KeepMeter Lifetime Pro**
- Product ID: **`de.kamilunavo.keepmeter.pro.lifetime`**
- Germany launch price: **€9.99** / the matching current App Store Connect price point
- Family Sharing: **off for v1**

Localizations:

German:
- Display Name: `KeepMeter Pro – Lifetime`
- Description: `Unbegrenzt aktive Käufe. Einmal zahlen.`

English (U.S.):
- Display Name: `KeepMeter Pro Lifetime`
- Description: `Unlimited active purchases. Pay once.`

Do not change the product ID or convert it into a subscription. Apple does not allow changing the product ID or purchase type after creation.

## 8. IAP App Review information

Use the reviewer notes in `docs/IAP_LIFETIME_PRO.md`.

Upload a release-candidate iPhone screenshot that clearly shows:

- KeepMeter Pro
- unlimited active purchases
- no subscription
- StoreKit-provided price/purchase button
- Restore Purchases

Do not include the DEBUG StoreKit QA section.

Apple's current App Store Connect documentation requires App Review information for the IAP, including the review screenshot and review notes. The screenshot is review-only and does not appear on the public App Store page.

After IAP metadata changes, allow for Apple sandbox propagation; Apple states that product metadata changes may take up to one hour to appear in the sandbox environment.

## 9. Provision KeepMeter GitHub release credentials

Only after the App Store Connect app record is correct, provision these KeepMeter repository secrets:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

Do not assume the same-named ZweiCheck secrets exist in KeepMeter.

The private key remains runner-temporary and is deleted by an `always()` cleanup step.

## 10. Physical-device preflight before first TestFlight

On a physical iPhone verify at minimum:

- fresh install / onboarding;
- create/edit/use purchase flow;
- force-quit and relaunch persistence;
- keep/return and archived read-only behavior;
- sixth-active-purchase Free-limit routing;
- notification permission flow;
- at least one actual local notification delivery;
- important Light/Dark screens;
- Dynamic Type spot-check;
- VoiceOver navigation spot-check.

The App Store sandbox/TestFlight Lifetime purchase/restore check happens after the first uploaded build, but the rest of the device behavior should not be deferred merely because Simulator CI is green.

## 11. First TestFlight upload

Only when the preceding gates are ready:

1. GitHub -> Actions -> **KeepMeter TestFlight**.
2. Run workflow from **main**.
3. Enter exact confirmation: `UPLOAD_KEEP_METER_0_1_0_BUILD_1`.
4. The workflow reruns release metadata gates.
5. It creates a signed Release archive for `generic/platform=iOS` using Automatic Signing and team `TKG684N5GL`.
6. It verifies bundle `de.kamilunavo.keepmeter`, version `0.1.0`, build `1` before upload.
7. It uploads with `manageAppVersionAndBuildNumber = false`.

A wrong branch, wrong confirmation, missing ASC credential, signing failure or build-identity mismatch must stop the upload.

Apple associates an uploaded build with the App Store Connect app/version using the bundle ID and version/build information in the app bundle. The first upload still has to finish Apple's processing before it appears in App Store Connect/TestFlight.

## 12. Real TestFlight / sandbox StoreKit gate

On the processed TestFlight build verify:

- Free state before purchase;
- real Lifetime Pro product and Apple-provided price load;
- successful one-time purchase;
- Pro entitlement unlocks immediately;
- unlimited active-purchase behavior works;
- terminate/relaunch preserves entitlement;
- explicit Restore Purchases works via `AppStore.sync()`;
- reinstall/restore behavior is correct for the same sandbox/TestFlight Apple account;
- no subscription wording appears anywhere.

Only after this gate should Lifetime Pro be considered production-path proven.

## 13. Final submission gate

Before App Review:

- verify both public URLs live again;
- re-audit final binary privacy answers;
- verify listing localizations and screenshots;
- verify IAP is attached/configured for review as required by App Store Connect;
- verify reviewer notes and IAP screenshot;
- verify age rating, content rights, DSA/app compliance and release settings in the current App Store Connect UI;
- submit only the exact build that passed the release/device/StoreKit gates.

## Stop conditions

Do not dispatch the first TestFlight upload if any of these is unresolved:

- wrong/missing App Store Connect app record;
- Bundle ID mismatch;
- SKU not intentionally set to `keepmeter-ios-001` before app-record creation;
- public Privacy/Support URLs not live;
- Lifetime IAP identity differs from `de.kamilunavo.keepmeter.pro.lifetime`;
- required KeepMeter ASC secrets are absent;
- required repository CI is red;
- basic physical-device preflight is not complete.
