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
 app.launchArguments=@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed",@"--keepMeterStoreScreenshot"];
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
 [app terminate];app.launchArguments=@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterStoreScreenshot"];
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
 [app terminate]; app.launchArguments=@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterStoreScreenshot",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed"];
 [app launch]; XCTAssertTrue([app.tabBars.buttons[@"Einstellungen"] waitForExistenceWithTimeout:15]);[app.tabBars.buttons[@"Einstellungen"] tap];
 XCUIElement*export=app.buttons[@"Käufe exportieren (CSV)"];for(int i=0;i<4&&!export.hittable;i++)[app swipeUp];XCTAssertTrue(export.hittable);[export tap];
 XCUIElement*save=app.buttons[@"Sichern"];XCTAssertTrue([save waitForExistenceWithTimeout:20]);[save tap];
 [NSThread sleepForTimeInterval:2];NSLog(@"AFTER_SAVE_TREE %@",app.debugDescription);[self capture:@"iPhone-08-export-saved"];
 XCTAssertFalse(app.textFields[@"DOCPicker.filenameTextField"].exists);
}
- (void)storeGallery:(BOOL)german {
 self.continueAfterFailure=NO;
 XCUIApplication*app=[[XCUIApplication alloc]initWithBundleIdentifier:@"de.kamilunavo.keepmeter"];
 NSMutableArray*args=[NSMutableArray arrayWithArray:@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",german?@"(de)":@"(en)",@"-AppleLocale",german?@"de_DE":@"en_US",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshot"]];
 if(german)[args addObject:@"--keepMeterStoreScreenshotSeed"];
 app.launchArguments=args;[app launch];
 NSString*name=german?@"Kopfhörer":@"Studio Headphones";
 XCTAssertTrue([app.staticTexts[name] waitForExistenceWithTimeout:20]);[self capture:@"01-purchase-centre"];
 [app swipeUp];[app.staticTexts[name] tap];XCTAssertTrue([app.navigationBars[name] waitForExistenceWithTimeout:5]);
 XCUIElement*category=[app.buttons matchingPredicate:[NSPredicate predicateWithFormat:@"label BEGINSWITH %@",german?@"Kategorie":@"Category"]].firstMatch;
 for(int i=0;i<4&&!category.hittable;i++)[app swipeUp];[category tap];
 [app.buttons[german?@"Technik":@"Technology"] tap];
 XCUIElement*photo=app.buttons[german?@"Belegfoto hinzufügen":@"Add receipt photo"];
 for(int i=0;i<4&&!photo.hittable;i++)[app swipeUp];[photo tap];
 NSLog(@"GALLERY_PHOTOS_TREE %@",app.debugDescription);
 XCUIElement*cell=app.images[@"PXGGridLayout-Info"].firstMatch;XCTAssertTrue([cell waitForExistenceWithTimeout:45]);
 [[cell coordinateWithNormalizedOffset:CGVectorMake(0.5,0.5)] tap];
 XCUIElement*add=app.buttons[german?@"Hinzufügen":@"Add"];if(add.exists&&add.hittable)[add tap];
 XCUIElement*receipt=app.images[german?@"Belegfoto":@"Receipt photo"];XCTAssertTrue([receipt waitForExistenceWithTimeout:10]);
 // Position the actual image from its accessibility frame, preserving the category above it.
 for(int i=0;i<4;i++) {
  CGFloat delta=260-receipt.frame.origin.y;
  if(fabs(delta)<35)break;
  CGFloat fraction=MAX(-0.3,MIN(0.3,delta/app.frame.size.height));
  XCUICoordinate*start=[app coordinateWithNormalizedOffset:CGVectorMake(0.85,0.5)];
  XCUICoordinate*end=[app coordinateWithNormalizedOffset:CGVectorMake(0.85,0.5+fraction)];
  [start pressForDuration:0.05 thenDragToCoordinate:end];
 }
 XCTAssertGreaterThanOrEqual(receipt.frame.origin.y,140);
 XCTAssertLessThan(CGRectGetMaxY(receipt.frame),850);
 [self capture:@"02-receipt-folder"];
 [app.navigationBars.buttons.firstMatch tap];
 [app.tabBars.buttons[german?@"Auswertung":@"Insights"] tap];[self capture:@"03-usage-insights"];
 [app.tabBars.buttons[german?@"Einstellungen":@"Settings"] tap];
 XCUIElement*export=app.buttons[german?@"Käufe exportieren (CSV)":@"Export purchases (CSV)"];
 for(int i=0;i<4&&!export.hittable;i++)[app swipeUp];XCTAssertTrue(export.hittable);[self capture:@"04-csv-export"];
 [app terminate];
}
- (void)testStoreGalleryDE { [self storeGallery:YES]; }
- (void)testStoreGalleryEN { [self storeGallery:NO]; }
- (void)testDuoLayout {
 self.continueAfterFailure=NO;
 XCUIApplication*app=[[XCUIApplication alloc]initWithBundleIdentifier:@"de.kamilunavo.keepmeter"];
 app.launchArguments=@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed",@"--keepMeterStoreScreenshot"];
 [app launch];XCTAssertTrue([app.staticTexts[@"Kopfhörer"] waitForExistenceWithTimeout:30]);
 NSLog(@"DUO_APP_FRAME %@",NSStringFromCGRect(app.frame));
 [self capture:@"Duo-01-purchase-centre"];
 XCUIElement*add=app.buttons[@"Kauf hinzufügen"];XCTAssertTrue(add.exists);[add tap];
 NSLog(@"DUO_ADD_TREE %@",app.debugDescription);[self capture:@"Duo-02-add-purchase"];
 XCUIElement*cancel=app.buttons[@"Abbrechen"];XCTAssertTrue(cancel.exists);[cancel tap];
 [app swipeUp];[app.staticTexts[@"Kopfhörer"] tap];XCTAssertTrue([app.navigationBars[@"Kopfhörer"] waitForExistenceWithTimeout:5]);
 [self capture:@"Duo-03-purchase-details"];
 // iOS 27.1 exposes the native rail back action outside NavigationBar, with
 // a known legacy/modern automation-type mismatch. Prefer its actual label.
 XCUIElement*back=[[app descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:[NSPredicate predicateWithFormat:@"label == 'Zurück' OR label == 'Back'"]].firstMatch;
 if(back.exists && back.hittable) { [back tap]; }
 else {
  NSLog(@"DUO_BACK_TREE %@",app.debugDescription);
  // Screenshot-confirmed native rail back centre on this exact compact pose.
  XCTAssertEqualWithAccuracy(app.frame.size.width,466,1);
  XCTAssertEqualWithAccuracy(app.frame.size.height,678,1);
  [[app coordinateWithNormalizedOffset:CGVectorMake(0.898,0.289)] tap];
 }
 XCTAssertTrue([app.buttons[@"Kauf hinzufügen"] waitForExistenceWithTimeout:10]);
 for(NSString*tab in @[@"Auswertung",@"Archiv",@"Einstellungen"]){
  XCUIElement*button=app.buttons[tab];XCTAssertTrue(button.hittable);[button tap];
  [self capture:[@"Duo-" stringByAppendingString:tab]];
  for(XCUIElement*control in app.buttons.allElementsBoundByIndex){
   if(control.hittable){XCTAssertGreaterThanOrEqual(CGRectGetMinX(control.frame),-1);XCTAssertLessThanOrEqual(CGRectGetMaxX(control.frame),CGRectGetMaxX(app.frame)+1);}
  }
 }
 [app terminate];
}

// Host changes only real Device Hub posture controls. Files synchronize the UI test
// with that operator action; they never set application geometry or saved values.
- (void)waitForDuoOperator:(NSString*)stage app:(XCUIApplication*)app {
 NSString*directory=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/DuoTransition"];
 [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
 NSString*request=[directory stringByAppendingPathComponent:@"request.txt"];
 [stage writeToFile:request atomically:YES encoding:NSUTF8StringEncoding error:nil];
 NSLog(@"DUO_OPERATOR_STAGE %@ FRAME %@",stage,NSStringFromCGRect(app.frame));
 NSString*ack=[directory stringByAppendingPathComponent:[stage stringByAppendingString:@".ack"]];
 NSPredicate*ready=[NSPredicate predicateWithBlock:^BOOL(id _, NSDictionary*bindings) {
  return [[NSFileManager defaultManager] fileExistsAtPath:ack];
 }];
 XCTNSPredicateExpectation*expected=[[XCTNSPredicateExpectation alloc]initWithPredicate:ready object:self];
 XCTAssertEqual([XCTWaiter waitForExpectations:@[expected] timeout:180],XCTWaiterResultCompleted);
 [self capture:[@"Duo-transition-" stringByAppendingString:stage]];
}
- (void)testDuoLiveTransition {
 self.continueAfterFailure=NO;
 NSString*directory=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/DuoTransition"];
 for(NSString*owned in @[@"01-closed.ack",@"02-open-with-keyboard.ack",@"03-partial.ack",@"04-closed-with-keyboard.ack",@"request.txt"]) {
  [[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:owned] error:nil];
 }
 XCUIApplication*app=[[XCUIApplication alloc]initWithBundleIdentifier:@"de.kamilunavo.keepmeter"];
 app.launchArguments=@[@"--keepMeterProviderDisabledQA",@"-hasCompletedOnboarding",@"YES",@"-AppleLanguages",@"(de)",@"-AppleLocale",@"de_DE",@"--keepMeterRuntimeSeed",@"--keepMeterStoreScreenshotSeed",@"--keepMeterStoreScreenshot"];
 [app launch];XCTAssertTrue([app.staticTexts[@"Kopfhörer"] waitForExistenceWithTimeout:45]);
 [self waitForDuoOperator:@"01-closed" app:app];CGRect compact=app.frame;
 XCUIElement*add=app.buttons[@"Kauf hinzufügen"];XCTAssertTrue(add.hittable);[add tap];
 XCUIElement*name=[app.textFields elementBoundByIndex:0];
 XCTAssertTrue([name waitForExistenceWithTimeout:10]);[name tap];[name typeText:@"Duo-QA-20261023"];
 XCTAssertTrue(app.keyboards.firstMatch.exists);
 [self waitForDuoOperator:@"02-open-with-keyboard" app:app];
 XCTAssertEqualObjects(name.value,@"Duo-QA-20261023");
 XCTAssertTrue(app.keyboards.firstMatch.exists);
 XCTAssertGreaterThan(fabs(app.frame.size.width-compact.size.width)+fabs(app.frame.size.height-compact.size.height),100);
 NSLog(@"DUO_EXPANDED_FRAME %@",NSStringFromCGRect(app.frame));
 [self waitForDuoOperator:@"03-partial" app:app];XCTAssertEqualObjects(name.value,@"Duo-QA-20261023");
 [self waitForDuoOperator:@"04-closed-with-keyboard" app:app];
 XCTAssertEqualObjects(name.value,@"Duo-QA-20261023");
 XCTAssertEqualWithAccuracy(app.frame.size.width,compact.size.width,2);
 XCTAssertEqualWithAccuracy(app.frame.size.height,compact.size.height,2);
 XCUIElement*cancel=app.buttons[@"Abbrechen"];XCTAssertTrue(cancel.hittable);[cancel tap];
 XCTAssertTrue(app.buttons[@"Kauf hinzufügen"].hittable);
 XCTAssertFalse(app.navigationBars[@"Neuer Kauf"].exists);
 [app terminate];
}

@end
