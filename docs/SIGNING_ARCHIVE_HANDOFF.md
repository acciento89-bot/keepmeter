# KeepMeter — Signing & Archive Handoff

Last updated: 2026-08-19
Status: STATIC SIGNING CONFIGURATION ONLY — NO TESTFLIGHT UPLOAD YET

## Locked identity

- Target: `KeepMeter`
- Bundle ID: `de.kamilunavo.keepmeter`
- Apple Development Team: `TKG684N5GL`
- Signing style: Automatic
- Archive configuration: Release
- Device family: iPhone
- Versioned signing config: `Config/Signing.xcconfig`

The signing config matches the Kamilunavo Apple team already used by the existing ZweiCheck iOS release pipeline. KeepMeter does not need a fragile project-file-only team setting: release/archive tooling must apply `Config/Signing.xcconfig` explicitly with `-xcconfig`.

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

## Future signed Archive path

The existing Kamilunavo/ZweiCheck release model establishes the intended pattern:

1. provide an App Store Connect API key to the CI job;
2. archive with `xcodebuild` for `generic/platform=iOS`, `-xcconfig Config/Signing.xcconfig` and `-allowProvisioningUpdates`;
3. authenticate provisioning with the App Store Connect key;
4. export with `method = app-store-connect`, `destination = upload`, `signingStyle = automatic`, and team `TKG684N5GL`;
5. verify the archive/app signature before export/upload.

Expected credential names used by the existing Kamilunavo pattern are:

- `ASC_ISSUER_ID`
- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`

Do **not** assume those repository secrets exist in KeepMeter merely because they exist in another repository. Secret presence must be established before a signed workflow is enabled.

## Explicit boundary

Gate 20 does **not**:

- create or import certificates;
- create provisioning profiles;
- add App Store Connect credentials;
- create an upload workflow;
- archive a signed physical-device build;
- upload to TestFlight;
- consume/increment a TestFlight build number.

The first TestFlight upload should happen only after App Store Connect/IAP configuration and the remaining physical-device gates are ready, so an intermediate build number is not burned just to test signing infrastructure.
