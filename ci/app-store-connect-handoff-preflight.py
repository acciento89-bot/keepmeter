#!/usr/bin/env python3
import json
import re
from pathlib import Path

SETUP_PATH = Path("metadata/AppStoreConnectSetup.json")
LISTING_PATH = Path("metadata/AppStoreListing.json")
WORKFLOW_PATH = Path(".github/workflows/testflight.yml")

setup = json.loads(SETUP_PATH.read_text(encoding="utf-8"))
listing = json.loads(LISTING_PATH.read_text(encoding="utf-8"))
workflow = WORKFLOW_PATH.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


app = setup["appRecord"]
require(app["platform"] == "iOS", "ASC platform must remain iOS")
require(app["name"] == "KeepMeter", "ASC app name drifted")
require(app["primaryLanguage"] == "German", "ASC primary language must remain German")
require(app["bundleId"] == "de.kamilunavo.keepmeter", "ASC bundle ID drifted")
require(app["sku"] == "keepmeter-ios-001", "ASC SKU drifted; SKU is immutable after app-record creation")
require(bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", app["sku"])), "ASC SKU contains unsupported characters")
require(app["primaryCategory"] == "Utilities", "ASC primary category drifted")
require(app["basePrice"] == "Free", "KeepMeter v1 app binary must remain free; monetization is Lifetime Pro IAP")
require(app["marketingVersion"] == "0.1.0", "ASC marketing version drifted")
require(app["buildNumber"] == "1", "ASC first build number drifted")

locales = setup["localizations"]
require(locales == ["de-DE", "en-US"], "ASC localization order/content drifted")
require(set(listing.keys()) == set(locales), "ASC setup locales must exactly match AppStoreListing.json")
require(listing["de-DE"]["name"] == "KeepMeter", "German App Store name drifted")
require(listing["en-US"]["name"] == "KeepMeter", "English App Store name drifted")

urls = setup["urls"]
require(urls["privacyPolicy"] == "https://kamilunavo.com/keepmeter/privacy", "Privacy Policy URL drifted")
require(urls["support"] == "https://kamilunavo.com/support", "Support URL drifted")
require(isinstance(urls["liveVerified"], bool), "URL liveVerified flag must be boolean")

privacy = setup["privacy"]
require(privacy["dataCollected"] is False, "Current v1 privacy handoff must remain Data Not Collected")
require(privacy["tracking"] is False, "Current v1 privacy handoff must remain Tracking: No")
require(privacy["recheckFinalBinaryBeforeSubmission"] is True, "Final binary privacy recheck must remain mandatory")

iap = setup["lifetimePro"]
require(iap["type"] == "Non-Consumable", "Lifetime Pro must remain Non-Consumable")
require(iap["referenceName"] == "KeepMeter Lifetime Pro", "Lifetime Pro reference name drifted")
require(iap["productId"] == "de.kamilunavo.keepmeter.pro.lifetime", "Lifetime Pro product ID drifted")
require(iap["germanyLaunchPriceEUR"] == "9.99", "Lifetime Pro Germany launch price decision drifted")
require(iap["subscription"] is False, "KeepMeter v1 must not become a subscription")
require(iap["familySharing"] is False, "KeepMeter v1 Family Sharing decision drifted")
require(iap["reviewScreenshotRequired"] is True, "IAP App Review screenshot requirement must remain explicit")
require(iap["reviewNotesRequired"] is True, "IAP review notes requirement must remain explicit")
require(iap["de-DE"]["displayName"] == "KeepMeter Pro – Lifetime", "German IAP display name drifted")
require(iap["de-DE"]["description"] == "Unbegrenzt aktive Käufe. Einmal zahlen.", "German IAP description drifted")
require(iap["en-US"]["displayName"] == "KeepMeter Pro Lifetime", "English IAP display name drifted")
require(iap["en-US"]["description"] == "Unlimited active purchases. Pay once.", "English IAP description drifted")

compliance = setup["euCompliance"]
require(
    compliance["dsaTraderStatus"] == "VERIFY_EXISTING_ACCOUNT_AND_APP_SETTING_BEFORE_EU_DISTRIBUTION",
    "EU DSA trader-status verification gate drifted",
)

testflight = setup["testFlight"]
require(testflight["workflow"] == ".github/workflows/testflight.yml", "TestFlight workflow path drifted")
require(testflight["manualOnly"] is True, "TestFlight lane must remain manual-only")
require(testflight["requiredBranch"] == "main", "TestFlight lane must remain main-only")
require(testflight["confirmation"] == "UPLOAD_KEEP_METER_0_1_0_BUILD_1", "TestFlight confirmation/build identity drifted")
require(testflight["manageAppVersionAndBuildNumber"] is False, "Apple build-number management must remain disabled")
require(
    testflight["requiredSecrets"] == ["ASC_ISSUER_ID", "ASC_KEY_ID", "ASC_PRIVATE_KEY_B64"],
    "ASC secret handoff drifted",
)

require(testflight["confirmation"] in workflow, "TestFlight workflow no longer contains the locked upload confirmation")
require("manageAppVersionAndBuildNumber" in workflow and "<false/>" in workflow, "TestFlight workflow no longer visibly disables Apple build-number management")

print("✓ App Store Connect app-record identity is locked")
print("✓ Immutable SKU keepmeter-ios-001 is locked and syntactically valid")
print("✓ DE/EN listing locales match the machine-readable App Store listing")
print("✓ Privacy/support URLs and final-binary privacy recheck are locked")
print("✓ Lifetime Pro identity, pricing decision and App Review handoff are locked")
print("✓ EU DSA status remains an explicit Apple-account verification gate")
print("✓ TestFlight handoff matches the guarded 0.1.0 (1) upload lane")
