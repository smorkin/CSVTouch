//
//  CSVPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
#import <iAd/iAd.h>
#endif


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
+ (BOOL) enablePhoneLinks;
+ (BOOL) useFixedWidth;
+ (BOOL) definedFixedWidths;
+ (BOOL) showStatusBar;
+ (BOOL) showDetailsToolbar;
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
+ (NSDate *) nextDownload; // Returns nil if none set
+ (NSDate *) lastDownload;
+ (void) setLastDownload:(NSDate *)lastDownload;
+ (BOOL) simpleMode;
+ (BOOL) blankWordSeparator;
+ (int) maxSafeBackgroundMinutes;

// This is temporary, while downloading a file with addresses to CSV files
+ (BOOL) hideAddress;
+ (void) setHideAddress:(BOOL)hide;

+ (BOOL) hasBeenUpgradedToCustomExtension;
+ (void) setHasBeenUpgradedToCustomExtension;

+ (void) applySettings:(NSArray *)settings;

+ (BOOL) restrictedDataVersionRunning;

+ (void) updateSortingMask; // Needs to be called as part of initialization
+ (NSUInteger) sortingMask;
extern NSUInteger sortingMask; // This is available for performance-critical operations

+ (BOOL) modifyItemsTableViewSize:(BOOL)increase;

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
+ (BOOL) canUseAbstractBannerNames;
#endif

@end
