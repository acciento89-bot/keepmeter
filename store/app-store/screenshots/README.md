# KeepMeter 1.1.0 iPhone gallery

Native iPhone 17 Pro Max, iOS 26.5, 1320×2868. The DE and EN galleries show the purchase centre, receipt folder, insights and CSV export. Screenshots are XCTest attachments from the final running app; no app interface is composited or redrawn.

Use the dedicated QA simulator only. Install the current debug app, import the matching synthetic receipt from `ci/fixtures/store-receipts` into the simulator photo library, then run the relevant `KeepMeterUITests/testStoreGalleryDE` or `testStoreGalleryEN` method. Use a clean app installation when changing language and import the matching receipt last. The actual Photos picker must be available; a fresh simulator may require its own restart after library migration. Gallery tests never tap purchase, restore or redemption controls.

The receipt is positioned using its actual accessibility frame and checked for full visibility before capture. No iPad support is asserted: the shipped app remains iPhone only.
