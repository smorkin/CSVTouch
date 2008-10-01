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
	IBOutlet OzyRotatableViewController *aboutController;
}

+ (CSVPreferencesController *) sharedInstance;

@end


@interface CSVPreferencesController (PreferenceData)

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL) emergencyMode;
- (void) applicationWillTerminate;

+ (NSString *) delimiter;
+ (NSInteger) tableViewSize;
+ (NSStringEncoding) encoding;
+ (BOOL) smartDelimiter;
+ (NSUInteger) maxNumberOfItemsToSort;
+ (BOOL) allowRotatableInterface;
+ (BOOL) useGroupingForItems;
+ (BOOL) showStatusBar;
+ (BOOL) keepQuotes;
+ (BOOL) showDebugInfo;
+ (BOOL) safeStart;
+ (BOOL) useBlackTheme;
+ (BOOL) useCorrectParsing;
+ (BOOL) useCorrectSorting;
+ (BOOL) useDetailsNavigation;
+ (BOOL) showInlineImages;

+ (void) updateSortingMask; // Needs to be called as part of initialization
+ (NSUInteger) sortingMask;
extern NSUInteger sortingMask; // This is available for performance-critical operations

@end
