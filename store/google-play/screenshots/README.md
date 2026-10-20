# KeepMeter 1.1.0 native store gallery

`de-DE` and `en-US` each contain five unmodified native 1080×2400 Android screenshots: purchase centre, return filters, receipt folder, usage insights and CSV export. They were captured by `StoreGalleryNativeTest.captureLocalizedPurchaseCentre` on the dedicated API 36 QA emulator. The successful final capture took 23.615 seconds. All purchases and receipt documents are synthetic local examples; no purchase, restore or redemption transaction was performed.

The instrumentation test changes only the isolated app's language and fixture database. It must never run against a personal device or production data. Wait for a cold emulator's system boot and background initialization before capture. Screenshot checks reject system ANR overlays. The app's photo import, migration and rotated CSV save are covered separately by `PurchaseCentreNativeTest`.
