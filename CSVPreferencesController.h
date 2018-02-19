//
//  CSVPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzymandiasAdditions.h"

#import <UIKit/UIKit.h>

@interface CSVPreferencesController : NSObject

+ (void) applicationDidFinishLaunching;

+ (NSString *) delimiter;
+ (CGFloat) itemsListFontSize;
+ (void) increaseItemsListFontSize;
+ (void) decreaseItemsListFontSize;
+ (BOOL) canIncreaseItemsListFontSize;
+ (BOOL) canDecreaseItemsListFontSize;
+ (CGFloat) detailsFontSize;
+ (void) increaseDetailsFontSize;
+ (void) decreaseDetailsFontSize;
+ (BOOL) canIncreaseDetailsFontSize;
+ (BOOL) canDecreaseDetailsFontSize;
+ (NSStringEncoding) encoding;
+ (BOOL) smartDelimiter;
+ (BOOL) useGroupingForItems;
+ (BOOL) groupNumbers;
+ (BOOL) enablePhoneLinks;
+ (BOOL) useFixedWidth;
+ (BOOL) definedFixedWidths;
+ (BOOL) showDetailsToolbar;
+ (BOOL) keepQuotes;
+ (BOOL) showDebugInfo;
+ (BOOL) safeStart;
+ (BOOL) useCorrectParsing;
+ (BOOL) useCorrectSorting;
+ (BOOL) showInlineImages;
+ (BOOL) clearSearchWhenQuickSelecting;
+ (BOOL) confirmLink;
+ (BOOL) usePassword;
+ (void) clearSetPassword;
+ (NSDate *) nextDownload; // Returns nil if none set
+ (NSDate *) lastDownload;
+ (void) setLastDownload:(NSDate *)lastDownload;
+ (BOOL) simpleMode;
+ (BOOL) blankWordSeparator;
+ (long) maxSafeBackgroundMinutes;
+ (NSURL *) lastUsedListURL;
+ (void) setLastUsedListURL:(NSURL *)URL;
+ (BOOL) synchronizeDownloadedFiles;

+ (NSInteger) selectedDetailsView;
+ (void) setSelectedDetailsView:(NSInteger) view;

+ (BOOL) showDeletedColumns;
+ (void) setShowDeletedColumns:(BOOL)yn;

// This is temporary, while downloading a file with addresses to CSV files
+ (BOOL) hideAddress;
+ (void) setHideAddress:(BOOL)hide;

+ (BOOL) hasBeenUpgradedToCustomExtension;
+ (void) setHasBeenUpgradedToCustomExtension;

+ (void) applySettings:(NSArray *)settings;

+ (BOOL) restrictedDataVersionRunning;

// This is not stored so restart of app -> back to default
+ (void) toggleReverseItemSorting;
+ (BOOL) reverseItemSorting;

+ (BOOL) hasShownHowTo;
+ (void) setHasShownHowTo;

+ (void) updateSortingMask; // Needs to be called as part of initialization
+ (NSUInteger) sortingMask;
extern NSUInteger sortingMask; // This is available for performance-critical operations

// Internal use
+ (NSString *) lastUsedURL;
+ (void) setLastUsedURL:(NSString *)URL;

// Check if prefs have changed while in background
+ (BOOL) defaultsHaveChanged;
+ (void) resetDefaultsHaveChanges;

@end
