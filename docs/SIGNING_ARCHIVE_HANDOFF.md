# KeepMeter — Signing & Archive Handoff

Last updated: 2026-08-19
Status: GUARDED MANUAL TESTFLIGHT LANE PREPARED — NO TESTFLIGHT UPLOAD YET

## Locked identity

- Target: `KeepMeter`
- Bundle ID: `de.kamilunavo.keepmeter`
- Apple Development Team: `TKG684N5GL`
- Signing style: Automatic
- Archive configuration: Release
- Device family: iPhone
- Versioned signing config: `Config/Signing.xcconfig`
- Current release identity: `0.1.0 (1)`

The signing config matches the Kamilunavo Apple team already used by the existing ZweiCheck iOS release pipeline. Release/archive tooling applies `Config/Signing.xcconfig` explicitly with `-xcconfig` instead of relying on a fragile project-file-only team setting.

## What Gate 20 verifies

`ci/release-preflight.sh` must fail if any of these drift:

- `Config/Signing.xcconfig` is missing or empty;
- `DEVELOPMENT_TEAM != TKG684N5GL`;
- `CODE_SIGN_STYLE != Automatic`;
- shared KeepMeter scheme missing;
- KeepMeter target not enabled for archiving;
- ArchiveAction missing;
- ArchiveAction no longer using Release.

The normal AppIcon, version, bundle ID, deployment target, Store listing/IAP gates and Privacy Manifest checks remain required by the complete CI pipeline.

## Guarded TestFlight lane

`.github/workflows/testflight.yml` prepares the signed archive/export/upload path but is intentionally **manual-only**.

Safety rules:

1. there is no `push`, `pull_request` or scheduled trigger;
2. the workflow must be dispatched from `main`;
3. the operator must type the exact confirmation phrase `UPLOAD_KEEP_METER_0_1_0_BUILD_1`;
4. the normal StoreKit metadata, App Store listing, localization and Release preflights run again before any signing attempt;
5. `ASC_ISSUER_ID`, `ASC_KEY_ID` and `ASC_PRIVATE_KEY_B64` must exist in the KeepMeter repository;
6. the signed archive is verified with `codesign`;
7. the archived bundle must still be exactly `de.kamilunavo.keepmeter`, version `0.1.0`, build `1` before upload;
8. export uses `method = app-store-connect`, `destination = upload`, `signingStyle = automatic`, team `TKG684N5GL`;
9. `manageAppVersionAndBuildNumber = false`, so Apple may not silently replace/increment the intended build number;
10. the temporary App Store Connect private key is removed with an `always()` cleanup step.

`ci/testflight-workflow-preflight.py` is part of normal CI and rejects drift in these safeguards. The upload workflow therefore cannot quietly become automatic or lose its build-identity guards without breaking the required iOS CI.

## Signed Archive / upload path

The prepared release sequence is:

1. checkout exact `main`;
2. require the explicit KeepMeter `0.1.0 (1)` upload confirmation;
3. pin the already-proven Xcode 26.2 toolchain;
4. rerun release/metadata/localization preflights;
5. materialize the App Store Connect API key only inside the runner temp directory;
6. archive with `xcodebuild` for `generic/platform=iOS`, `-xcconfig Config/Signing.xcconfig` and `-allowProvisioningUpdates`;
7. authenticate provisioning with the App Store Connect key;
8. verify archive signature plus exact bundle/version/build identity;
9. export/upload with Apple Cloud Signing using the locked team and no build-number management;
10. remove the API private key regardless of success/failure.

Expected KeepMeter repository secrets:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

Do **not** assume those repository secrets exist merely because the same names are used in ZweiCheck. Their presence is checked only when the manual TestFlight workflow is intentionally dispatched.

## Explicit boundary

Preparing and CI-gating this workflow does **not**:

- create the App Store Connect app record;
- create/configure the Lifetime Pro IAP in App Store Connect;
- add App Store Connect credentials to the repository;
- create or import certificates manually;
- create provisioning profiles manually;
- archive a signed physical-device build during normal CI;
- upload anything to TestFlight during normal CI;
- consume/increment a TestFlight build number.

The first manual dispatch remains blocked by release policy until the App Store Connect app/IAP prerequisites and remaining physical-device gates are ready. When version or build changes from `0.1.0 (1)`, both the explicit confirmation phrase and the archive identity guard must be updated deliberately in the same reviewed change.
