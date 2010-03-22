//
//  CSVPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CSVPreferencesController : NSObject

+ (void) applicationDidFinishLaunching;

+ (NSString *) delimiter;
+ (NSInteger) itemsTableViewSize;
+ (NSInteger) detailsTableViewSize;
+ (NSStringEncoding) encoding;
+ (BOOL) smartDelimiter;
+ (NSUInteger) maxNumberOfItemsToSort;
+ (BOOL) allowRotatableInterface;
+ (BOOL) useGroupingForItems;
+ (BOOL) groupNumbers;
+ (BOOL) showStatusBar;
+ (BOOL) keepQuotes;
+ (BOOL) showDebugInfo;
+ (BOOL) safeStart;
+ (BOOL) useBlackTheme;
+ (BOOL) useCorrectParsing;
+ (BOOL) useCorrectSorting;
+ (BOOL) useDetailsNavigation;
+ (BOOL) useDetailsSwipe;
+ (BOOL) useSwipeAnimation;
+ (BOOL) showInlineImages;
+ (NSUInteger) maxNumberOfItemsToLiveFilter;
+ (BOOL) clearSearchWhenQuickSelecting;
+ (BOOL) confirmLink;
+ (BOOL) alignHtml;
+ (BOOL) usePassword;
+ (void) clearSetPassword;

+ (BOOL) hasBeenUpgradedToCustomExtension;
+ (void) setHasBeenUpgradedToCustomExtension;

+ (BOOL) liteVersionRunning;

+ (void) updateSortingMask; // Needs to be called as part of initialization
+ (NSUInteger) sortingMask;
extern NSUInteger sortingMask; // This is available for performance-critical operations

+ (BOOL) modifyItemsTableViewSize:(BOOL)increase;

@end
