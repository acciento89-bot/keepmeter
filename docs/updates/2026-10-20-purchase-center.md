# KeepMeter purchase centre update
User authorization: 20 October 2026, ASO for Google/Apple plus meaningful larger updates; one app at a time. New scope replaces CSV-only proposal.

Deliver on iOS and Android: category assignment, receipt photo saved locally, search by purchase/merchant, category filter, due-in-seven-days view and sorting, CSV export for all active/archived purchases. Preserve existing data, paid entitlement, reminder rules and five-active-item free limit. No test purchases, redemptions or restore transactions. No new analytics/backends.

Store copy only describes tested functionality. Apple locked metadata goes with this meaningful update, not a text-only version. Current live promotional text may be edited independently. Android DE/EN short descriptions already saved as pending changes; do not claim publication. Google and Apple delivery only after native checks, existing signing and actual receipts. No other app automation changes; Pocket Rail monitor remains paused by human request.

Validation: CSV escaping/formula handling/empty exports, persistence migration and receipt save failure handling, filtering boundaries and accent-insensitive search; native builds followed by real UI checks of add/category/photo/search/export/relaunch. No stale QA or empty-data screenshots passed off as feature proof.

Local native QA now uses only the retained shared Duo under the root AGENTS.md; never erase or delete it. Cloud CI owns and cleans up its own temporary simulator. iPhone harness: install the current debug app on a clean app container, add a local example receipt to the simulator Photos library, then run ci/iOSNativeQA/KeepMeterQA.xcodeproj scheme KeepMeterUITests. It never taps billing or restoration. The Photos picker thumbnail identifier PXGGridLayout-Info was taken from the actual iOS 26.5 XCTest hierarchy; do not substitute arbitrary app images. Android formal instrumentation seeds only its own fixture database on the isolated QA device and exercises the real system CSV picker across rotation.

Store delivery remains pending. DE/EN metadata in metadata/AppStoreListing.json targets 1.1.0, not the currently live version. Historical immutable central-signing workflow remains pinned to its old reviewed artifact; do not reuse it for version 6. The current upload lane expects version 6 and must only run after release validation.

23 October: iOS build6 fixes the native Duo add-action loss after a sheet/keyboard fold cycle. Both actual Duo tests pass; see `docs/QA/ios-duo-20261023.md`. Build5 is superseded and must not be submitted. Release6 signing/upload and Apple review remain pending until separately verified.
