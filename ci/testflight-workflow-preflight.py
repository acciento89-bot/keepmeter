#!/usr/bin/env python3
from pathlib import Path
import json

WORKFLOW = Path('.github/workflows/testflight.yml')

if not WORKFLOW.is_file():
    raise SystemExit('TestFlight workflow is missing')

text = WORKFLOW.read_text(encoding='utf-8')
setup = json.loads(Path('metadata/AppStoreConnectSetup.json').read_text(encoding='utf-8'))
expected_version = setup['appRecord']['marketingVersion']
expected_build = setup['appRecord']['buildNumber']
expected_confirmation = setup['testFlight']['confirmation']

for forbidden in ('\n  push:', '\n  pull_request:', '\n  schedule:'):
    if forbidden in text:
        raise SystemExit(f'TestFlight workflow must remain manual-only; forbidden trigger found: {forbidden.strip()}')

required = (
    'workflow_dispatch:',
    expected_confirmation,
    'test "$GITHUB_REF" = "refs/heads/main"',
    'runs-on: macos-26',
    'sudo xcode-select -s /Applications/Xcode_26.2.app/Contents/Developer',
    'TEAM_ID: TKG684N5GL',
    'ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}',
    'ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}',
    'ASC_PRIVATE_KEY_B64: ${{ secrets.ASC_PRIVATE_KEY_B64 }}',
    'python3 ci/storekit-metadata-preflight.py',
    'python3 ci/app-store-listing-preflight.py',
    'python3 ci/localization-preflight.py',
    'bash ci/release-preflight.sh',
    "-destination 'generic/platform=iOS'",
    '-archivePath "$RUNNER_TEMP/KeepMeter.xcarchive"',
    '-xcconfig Config/Signing.xcconfig',
    '-allowProvisioningUpdates',
    '-authenticationKeyPath "$KEY_PATH"',
    '-authenticationKeyID "$ASC_KEY_ID"',
    '-authenticationKeyIssuerID "$ASC_ISSUER_ID"',
    'codesign --verify --deep --strict --verbose=2 "$APP"',
    'test "$BUNDLE_ID" = "de.kamilunavo.keepmeter"',
    f'test "$VERSION" = "{expected_version}"',
    f'test "$BUILD" = "{expected_build}"',
    '<string>app-store-connect</string>',
    '<string>upload</string>',
    '<string>automatic</string>',
    '<string>$TEAM_ID</string>',
    '<key>manageAppVersionAndBuildNumber</key>',
    '<false/>',
    '-exportArchive',
    'if: always()',
    'rm -f "$RUNNER_TEMP/AuthKey_${ASC_KEY_ID}.p8"',
)

missing = [fragment for fragment in required if fragment not in text]
if missing:
    formatted = '\n'.join(f'  - {fragment}' for fragment in missing)
    raise SystemExit(f'TestFlight workflow is missing required release safeguards:\n{formatted}')

confirm_index = text.index('Require intentional main-branch upload')
credentials_index = text.index('Require App Store Connect credentials')
archive_index = text.index('Archive signed KeepMeter Release')
identity_index = text.index('Verify signed archive identity')
upload_index = text.index('Upload exact build to TestFlight with Apple Cloud Signing')
cleanup_index = text.index('Remove App Store Connect API key')

if not (confirm_index < credentials_index < archive_index < identity_index < upload_index < cleanup_index):
    raise SystemExit('TestFlight safety steps are in an unsafe order')

if text.count('-allowProvisioningUpdates') < 2:
    raise SystemExit('Provisioning updates must be enabled for both archive and export')

if text.count('-authenticationKeyPath "$KEY_PATH"') < 2:
    raise SystemExit('ASC authentication key must be supplied to both archive and export')

if text.count('-authenticationKeyID "$ASC_KEY_ID"') < 2:
    raise SystemExit('ASC key ID must be supplied to both archive and export')

if text.count('-authenticationKeyIssuerID "$ASC_ISSUER_ID"') < 2:
    raise SystemExit('ASC issuer ID must be supplied to both archive and export')

print('✓ TestFlight workflow is workflow_dispatch-only')
print(f'✓ Upload is locked to main and explicit KeepMeter {expected_version} ({expected_build}) confirmation')
print('✓ Exact bundle/version/build identity is verified before upload')
print('✓ App Store Connect credentials and Automatic Signing path are pinned')
print('✓ App Store Connect is forbidden from auto-changing the build number')
print('✓ ASC private key cleanup remains an always-run final step')
