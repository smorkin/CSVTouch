//
//  CSVPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OzyRotatableViewController;

@interface CSVPreferencesController : UINavigationController <UITableViewDelegate>
{
	IBOutlet OzyRotatableViewController *prefsSelectionController;
	IBOutlet OzyRotatableViewController *dataPrefsController;
	IBOutlet OzyRotatableViewController *sortingPrefsController;
	IBOutlet OzyRotatableViewController *appearancePrefsController;
	IBOutlet OzyRotatableViewController *aboutController;
	IBOutlet OzyRotatableViewController *legalController;
	
	// Data
	IBOutlet UISegmentedControl *encodingControl;
	IBOutlet UISwitch *smartDelimiterSwitch;
	IBOutlet UISegmentedControl *delimiterControl;
	// Appearance
	IBOutlet UISegmentedControl *sizeControl;
	IBOutlet UISwitch *allowRotatableInterface;
	IBOutlet UISwitch *useGroupingForItems;
	IBOutlet UISwitch *showStatusBar;
	// Sorting
	IBOutlet UISwitch *numericCompareSwitch;
	IBOutlet UISwitch *caseSensitiveCompareSwitch;
	IBOutlet UITextField *maxNumberOfObjectsToSort;	
}

+ (CSVPreferencesController *) sharedInstance;

@end


@interface CSVPreferencesController (PreferenceData)

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL) emergencyMode;
- (void) applicationWillTerminate;

- (IBAction) sizeControlChanged:(id)sender;
- (IBAction) delimiterControlChanged:(id)sender;
- (IBAction) encodingControlChanged:(id)sender;
- (IBAction) sortingChanged:(id)sender;
- (IBAction) rotationChanged:(id)sender;
- (IBAction) groupingChanged:(id)sender;
- (IBAction) showStatusBarChanged:(id)sender;

+ (NSString *) delimiter;
+ (NSInteger) tableViewSize;
+ (NSStringEncoding) encoding;
+ (BOOL) smartDelimiter;
+ (NSUInteger) maxNumberOfObjectsToSort;
+ (BOOL) allowRotatableInterface;
+ (BOOL) useGroupingForItems;
+ (BOOL) showStatusBar;
+ (NSUInteger) sortingMask;
extern NSUInteger sortingMask; // This is available for performance-critical operations

+ (BOOL) useGroupingForItemsHasChangedSinceStart;

@end
