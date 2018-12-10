//
//  CSVPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzymandiasAdditions.h"

#import <UIKit/UIKit.h>

typedef enum FixedWidthAlternative{
    NO_FIXED_WIDTHS = 0,
    PREDEFINED_FIXED_WIDTHS,
    AUTOMATIC_FIXED_WIDTHS
}FixedWidthAlternative;

@interface CSVPreferencesController : NSObject

+ (void) applicationDidFinishLaunching;

// Setting with nil -> smart delimiter
+ (void) setDelimiter:(NSString *)delimiter;
+ (NSString *) delimiter;
+ (BOOL) smartDelimiter;
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
+ (void) setStringEncoding:(NSStringEncoding)encoding;
+ (NSStringEncoding) encoding;
+ (void) setUseGroupingForItems:(BOOL)yn;
+ (BOOL) useGroupingForItems;
+ (void) setGroupNumbers:(BOOL)yn;
+ (BOOL) groupNumbers;
+ (void) setUseMonospacedFont:(BOOL)yn;
+ (BOOL) useMonospacedFont;
+ (void) setFixedWidthsAlternative:(FixedWidthAlternative)alt;
+ (FixedWidthAlternative) fixedWidthsAlternative;
+ (void) setKeepQuotes:(BOOL)yn;
+ (BOOL) keepQuotes;
+ (void) setUseCorrectParsing:(BOOL)yn;
+ (BOOL) useCorrectParsing;
+ (void) setShowInlineImages:(BOOL)yn;
+ (BOOL) showInlineImages;
+ (void) setSmartSearchClearing:(BOOL)yn;
+ (BOOL) smartSeachClearing;
+ (BOOL) useAutomatedDownload;
+ (void) setUseAutomatedDownload:(BOOL)yn;
+ (void) setConfiguredDownloadHour:(NSInteger)hour minute:(NSInteger)minute;
+ (NSInteger) configuredDownloadHour; // 0-23
+ (NSInteger) configuredDownloadMinute; // 0-59
+ (NSDate *) nextDownload; // Returns nil if none set
+ (NSDate *) lastDownload;
+ (void) setLastDownload:(NSDate *)lastDownload;
+ (void) setBlankWordSeparator:(BOOL)yn;
+ (BOOL) blankWordSeparator;
+ (NSURL *) lastUsedListURL;
+ (void) setLastUsedListURL:(NSURL *)URL;
+ (void) setCaseSensitiveSort:(BOOL)yn;
+ (BOOL) caseSensitiveSort;
+ (void) setNumericSort:(BOOL)yn;
+ (BOOL) numericSort;
+ (void) setLiteralSort:(BOOL)yn;
+ (BOOL) literalSort;
+ (void) setCorrectSort:(BOOL)yn;
+ (BOOL) correctSort;
+ (void) setMultilineItemCells:(BOOL)yn;
+ (BOOL) multilineItemCells;

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

+ (NSString *) cssFileName;

// Internal use
+ (NSString *) lastUsedURL;
+ (void) setLastUsedURL:(NSString *)URL;

// Check if prefs have changed while in background
+ (BOOL) defaultsHaveChanged;
+ (void) resetDefaultsHaveChanges;

@end
