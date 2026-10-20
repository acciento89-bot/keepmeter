#import <XCTest/XCTest.h>
@interface KeepMeterUITests : XCTestCase
@end
@implementation KeepMeterUITests
- (void)capture:(NSString*)name {
 XCTAttachment*a=[XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];a.name=name;a.lifetime=XCTAttachmentLifetimeKeepAlways;[self addAttachment:a];
}
- (void)testPurchaseCentre {
 self.continueAfterFailure=NO;
 XCUIApplication*app=[[XCUIApplication alloc]initWithBundleIdentifier:@"de.kamilunavo.keepmeter"];
 app.launchArguments=@[@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed",@"--keepMeterStoreScreenshot"];
 [app launch];XCTAssertTrue([app.staticTexts[@"Kopfhörer"] waitForExistenceWithTimeout:20]);[self capture:@"iPhone-01-purchase-centre"];
 [app swipeUp]; [app.staticTexts[@"Kopfhörer"] tap]; XCTAssertTrue([app.navigationBars[@"Kopfhörer"] waitForExistenceWithTimeout:5]);
 XCUIElement*category=[app.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"label BEGINSWITH %@",@"Kategorie"]].firstMatch;
 for(int i=0;i<4&&!category.hittable;i++)[app swipeUp];XCTAssertTrue(category.exists);[category tap];
 XCTAssertTrue([app.buttons[@"Technik"] waitForExistenceWithTimeout:5]);[app.buttons[@"Technik"] tap];[self capture:@"iPhone-02-purchase-folder"];
 XCUIElement*photo=app.buttons[@"Belegfoto hinzufügen"];for(int i=0;i<3&&!photo.hittable;i++)[app swipeUp];XCTAssertTrue(photo.hittable);[photo tap];
 [NSThread sleepForTimeInterval:2];NSLog(@"PHOTO_PICKER_TREE %@",app.debugDescription);
 XCUIElement*cell=app.images[@"PXGGridLayout-Info"].firstMatch;
 XCTAssertTrue([cell waitForExistenceWithTimeout:60], @"System photo library should expose the seeded receipt");
 // Photos exposes a visible image rectangle but no hittable AX point on iOS 26.5.
 [[cell coordinateWithNormalizedOffset:CGVectorMake(0.5,0.5)] tap];XCUIElement*add=app.buttons[@"Hinzufügen"];if(add.exists)[add tap];
 [NSThread sleepForTimeInterval:2];NSLog(@"AFTER_PHOTO_TREE %@",app.debugDescription);
 XCUIElement*done=app.buttons[@"Fertig"];if(done.exists&&done.hittable)[done tap];
 XCTAssertTrue([app.images[@"Belegfoto"] waitForExistenceWithTimeout:10]);[self capture:@"iPhone-03-receipt-photo"];
 [app terminate];app.launchArguments=@[@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterStoreScreenshot"];
 [app launch];XCTAssertTrue([app.staticTexts[@"Kopfhörer"] waitForExistenceWithTimeout:15]);[app swipeUp]; [app.staticTexts[@"Kopfhörer"] tap]; XCTAssertTrue([app.navigationBars[@"Kopfhörer"] waitForExistenceWithTimeout:5]);
 XCUIElement*receipt=app.images[@"Belegfoto"];for(int i=0;i<4&&!receipt.hittable;i++)[app swipeUp];XCTAssertTrue(receipt.exists);[self capture:@"iPhone-04-restarted-receipt"];
 [app.navigationBars.buttons.firstMatch tap];
 XCUIElement*search=app.searchFields.firstMatch;if(!search.hittable)[app swipeDown];XCTAssertTrue(search.exists);[search tap];[search typeText:@"ruck"];
 XCTAssertTrue(app.staticTexts[@"Reiserucksack"].exists);XCTAssertFalse(app.staticTexts[@"Kopfhörer"].exists);[self capture:@"iPhone-05-search"];
 [app terminate]; [app launch]; XCTAssertTrue([app.tabBars.buttons[@"Einstellungen"] waitForExistenceWithTimeout:15]);
 [app.tabBars.buttons[@"Einstellungen"] tap];
 XCUIElement*export=app.buttons[@"Käufe exportieren (CSV)"];for(int i=0;i<4&&!export.hittable;i++)[app swipeUp];XCTAssertTrue(export.hittable);[self capture:@"iPhone-06-export-settings"];[export tap];
 [NSThread sleepForTimeInterval:2];NSLog(@"EXPORT_PICKER_TREE %@",app.debugDescription);[self capture:@"iPhone-07-native-export-picker"];
 XCTAssertTrue(app.buttons[@"Abbrechen"].exists || app.buttons[@"Exportieren"].exists || app.buttons[@"Sichern"].exists);
}
- (void)testNativeCSVSave {
 self.continueAfterFailure=NO;
 XCUIApplication*app=[[XCUIApplication alloc]initWithBundleIdentifier:@"de.kamilunavo.keepmeter"];
 [app terminate]; app.launchArguments=@[@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterStoreScreenshot",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed"];
 [app launch]; XCTAssertTrue([app.tabBars.buttons[@"Einstellungen"] waitForExistenceWithTimeout:15]);[app.tabBars.buttons[@"Einstellungen"] tap];
 XCUIElement*export=app.buttons[@"Käufe exportieren (CSV)"];for(int i=0;i<4&&!export.hittable;i++)[app swipeUp];XCTAssertTrue(export.hittable);[export tap];
 XCUIElement*save=app.buttons[@"Sichern"];XCTAssertTrue([save waitForExistenceWithTimeout:20]);[save tap];
 [NSThread sleepForTimeInterval:2];NSLog(@"AFTER_SAVE_TREE %@",app.debugDescription);[self capture:@"iPhone-08-export-saved"];
 XCTAssertFalse(app.textFields[@"DOCPicker.filenameTextField"].exists);
}
@end
