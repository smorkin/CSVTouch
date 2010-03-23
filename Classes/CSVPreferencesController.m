//
//  CSVPreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVPreferencesController.h"
#import "OzymandiasAdditions.h"
#import "OzyTableViewController.h"


@implementation CSVPreferencesController


#define PREFS_ENCODING @"encoding"
#define PREFS_SMART_DELIMITER @"smartDelimiter"
#define PREFS_DELIMITER @"delimiter"
#define PREFS_SORTING_MASK @"sortingMask"
#define PREFS_ITEMS_TABLEVIEW_SIZE @"tableViewSize"
#define PREFS_DETAILS_TABLEVIEW_SIZE @"detailsTableViewSize"
#define PREFS_MAX_NUMBER_TO_SORT @"maxNumberOfItemsToSort"
#define PREFS_ALLOW_ROTATION @"allowRotation"
#define PREFS_USE_GROUPING_FOR_ITEMS @"useGroupingForItems"
#define PREFS_GROUP_NUMBERS @"groupNumbers"
#define PREFS_ENABLE_PHONE_LINKS @"enablePhoneLinks"
#define PREFS_SHOW_STATUS_BAR @"showStatusBar"
#define PREFS_SAFE_START @"safeStart"
#define PREFS_KEEP_QUOTES @"keepQuotes"
#define PREFS_SHOW_DEBUG_INFO @"showDebugInfo"
#define PREFS_USE_BLACK_THEME @"useBlackTheme"
#define PREFS_USE_CORRECT_PARSING @"useCorrectParsing"
#define PREFS_USE_CORRECT_SORTING @"useCorrectSorting"
#define PREFS_REMOVE_DETAILS_NAVIGATION @"useDetailsNavigation"
#define PREFS_USE_DETAILS_SWIPE @"useDetailsSwipe"
#define PREFS_USE_SWIPE_ANIMATION @"useSwipeAnimation"
#define PREFS_SHOW_INLINE_IMAGES @"showInlineImages"
#define PREFS_NUMBER_SENSITIVE_SORTING @"numberSensitiveSorting"
#define PREFS_CASE_SENSITIVE_SORTING @"caseSensitiveSorting"
#define PREFS_LITERAL_SORTING @"literalSorting"
#define PREFS_MAX_NUMBER_LIVE_FILTER @"maxNumberLiveFilter"
#define PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING @"clearSearchWhenQuickSelecting"
#define PREFS_CONFIRM_LINK @"confirmLink"
#define PREFS_ALIGN_HTML @"alignHtml"
#define PREFS_USE_PASSWORD @"usePassword"
#define PREFS_HAS_BEEN_UPGRADED_TO_CUSTOM_EXTENSION @"hasBeenUpgradedToCustomExtension"


NSUInteger sortingMask;

+ (void) applicationDidFinishLaunching
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// Clean out old settings
	[defaults removeObjectForKey:@"aboutID"];
	[defaults removeObjectForKey:@"dataID"];
	[defaults removeObjectForKey:@"sortingID"];
	[defaults removeObjectForKey:@"appearanceID"];
	[defaults removeObjectForKey:@"currentPrefsControllerStack"];

	// Setup sortingMask
	sortingMask = NSNumericSearch ^ NSCaseInsensitiveSearch ^ NSLiteralSearch;
	id obj;
	obj = [defaults objectForKey:PREFS_NUMBER_SENSITIVE_SORTING];
	if( obj && [obj boolValue] == FALSE )
		sortingMask ^= NSNumericSearch;
	obj = [defaults objectForKey:PREFS_CASE_SENSITIVE_SORTING];
	if( obj && [obj boolValue] == TRUE )
		sortingMask ^= NSCaseInsensitiveSearch;
	obj = [defaults objectForKey:PREFS_LITERAL_SORTING];
	if( obj && [obj boolValue] == FALSE )
		sortingMask ^= NSLiteralSearch;
}


+ (NSString *) delimiter
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *s = [defaults stringForKey:PREFS_DELIMITER];
	if( !s )
		s = @";";
	return s;
}

+ (BOOL) smartDelimiter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SMART_DELIMITER];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SMART_DELIMITER];
	else
		return YES;
}

+ (NSInteger) itemsTableViewSize
{
	NSInteger s = [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_ITEMS_TABLEVIEW_SIZE];
	if( s < 0 || s > OZY_MINI )
		return OZY_SMALL;
	else
		return s;
}

+ (NSInteger) detailsTableViewSize
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_DETAILS_TABLEVIEW_SIZE];
	NSInteger s = [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_DETAILS_TABLEVIEW_SIZE];
	if( !obj || s < 0 || s > OZY_MINI )
		return OZY_NORMAL;
	else
		return s;
}

+ (BOOL) modifyItemsTableViewSize:(BOOL)increase
{
	int newSize = [self itemsTableViewSize];
	
	// Stupidly enough the sizes go backwards...
	if( increase) 
		newSize--;
	else
		newSize++;
	if( newSize >= OZY_NORMAL && newSize <= OZY_MINI )
	{
		[[NSUserDefaults standardUserDefaults] setInteger:newSize
												   forKey:PREFS_ITEMS_TABLEVIEW_SIZE];
		return YES;
	}
	else
		return NO;
}

+ (NSUInteger) maxNumberOfItemsToSort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_MAX_NUMBER_TO_SORT];
}	

+ (NSStringEncoding) encoding
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ENCODING];
	if( obj )
		return [obj intValue];
	else
		return NSISOLatin1StringEncoding;
}

+ (BOOL) allowRotatableInterface
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ALLOW_ROTATION];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (BOOL) useGroupingForItems
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_GROUPING_FOR_ITEMS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (BOOL) groupNumbers
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_GROUP_NUMBERS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}


+ (BOOL) enablePhoneLinks
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ENABLE_PHONE_LINKS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (BOOL) showStatusBar
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SHOW_STATUS_BAR] )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_STATUS_BAR];
	else
		return YES;
}

+ (BOOL) keepQuotes
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_KEEP_QUOTES];
}

+ (BOOL) showDebugInfo
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_DEBUG_INFO];
}

+ (BOOL) useBlackTheme
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_BLACK_THEME];
}

+ (BOOL) safeStart
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SAFE_START];
}

+ (BOOL) useCorrectParsing
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_CORRECT_PARSING];
}

+ (BOOL) useCorrectSorting
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_CORRECT_SORTING];
}

+ (BOOL) useDetailsNavigation
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_REMOVE_DETAILS_NAVIGATION];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_REMOVE_DETAILS_NAVIGATION];
	else
		return YES;
}

+ (BOOL) useDetailsSwipe
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_DETAILS_SWIPE];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_DETAILS_SWIPE];
	else
		return YES;
}

+ (BOOL) useSwipeAnimation
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_SWIPE_ANIMATION];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_SWIPE_ANIMATION];
	else
		return YES;
}

+ (BOOL) showInlineImages
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SHOW_INLINE_IMAGES] )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_INLINE_IMAGES];
	else
		return YES;
}

+ (NSUInteger) maxNumberOfItemsToLiveFilter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_NUMBER_LIVE_FILTER];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_MAX_NUMBER_LIVE_FILTER];
	else
		return 1500;
}

+ (BOOL) clearSearchWhenQuickSelecting
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
	else
		return YES;
}

+ (BOOL) confirmLink
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_CONFIRM_LINK];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_CONFIRM_LINK];
	else
		return NO;
}

+ (BOOL) alignHtml
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ALIGN_HTML];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_ALIGN_HTML];
	else
		return YES;
}

+ (BOOL) usePassword
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_PASSWORD];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_PASSWORD];
	else
		return NO;
}

+ (void) clearSetPassword
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_USE_PASSWORD];
}

+ (BOOL) liteVersionRunning
{
#ifdef CSV_LITE
	return YES;
#else
	return NO;
#endif
}


+ (BOOL) hasBeenUpgradedToCustomExtension
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_HAS_BEEN_UPGRADED_TO_CUSTOM_EXTENSION];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_HAS_BEEN_UPGRADED_TO_CUSTOM_EXTENSION];
	else
		return NO;
}

+ (void) setHasBeenUpgradedToCustomExtension
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PREFS_HAS_BEEN_UPGRADED_TO_CUSTOM_EXTENSION];
}

+ (void) updateSortingMask
{
	sortingMask = NSNumericSearch ^ NSCaseInsensitiveSearch ^ NSLiteralSearch;
	id obj;
	obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_NUMBER_SENSITIVE_SORTING];
	if( obj && [obj boolValue] == FALSE )
		sortingMask = NSCaseInsensitiveSearch;
	obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_CASE_SENSITIVE_SORTING];
	if( obj && [obj boolValue] == TRUE )
		sortingMask ^= NSCaseInsensitiveSearch;
	obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_LITERAL_SORTING];
	if( obj && [obj boolValue] == TRUE )
		sortingMask ^= NSLiteralSearch;
}

+ (NSUInteger) sortingMask
{
	NSString *sorting = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SORTING_MASK];
	if( sorting )
		sortingMask = [sorting intValue];
	else
		sortingMask = NSNumericSearch ^ NSCaseInsensitiveSearch;
	return sortingMask;
}

//- (IBAction) sizeControlChanged:(id)sender
//{
//	if( startupInProgress )
//		return;
//	
//	[CSVPreferencesController setTableViewSize:[sizeControl selectedSegmentIndex]];
//	[[CSVDataViewController sharedInstance] setSize:[sizeControl selectedSegmentIndex]];
//}
//

@end
