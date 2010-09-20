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
#define PREFS_USE_FIXED_WIDTH @"useFixedWidth"
#define PREFS_DEFINED_FIXED_WIDTHS @"definedFixedWidths"
#define PREFS_SHOW_STATUS_BAR @"showStatusBar"
#define PREFS_SHOW_DETAILS_TOOLBAR @"showDetailsToolbar"
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
#define PREFS_HIDE_ADDRESS @"hideAddress"

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

+ (BOOL) useFixedWidth
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_FIXED_WIDTH];
	if( obj )
		return [obj boolValue];
	else
		return NO;
}

+ (BOOL) definedFixedWidths
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_DEFINED_FIXED_WIDTHS];
	if( obj )
		return [obj boolValue];
	else
		return NO;
}

+ (BOOL) showDetailsToolbar
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SHOW_DETAILS_TOOLBAR];
	if( obj )
		return [obj boolValue];
	else
		return NO;
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

static BOOL hideAdress = NO;

+ (BOOL) hideAddress
{
	return hideAdress;
}

+ (void) setHideAddress:(BOOL)hide
{
	hideAdress = hide;
}


+ (void) applySettings:(NSArray *)settings
{
	for( NSString *s in settings )
	{
		NSArray *words = [s componentsSeparatedByString:@" "];
		if( [words count] == 2 )
		{
			if( [[words objectAtIndex:0] isEqualToString:PREFS_ENCODING] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_ENCODING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SMART_DELIMITER] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														   forKey:PREFS_SMART_DELIMITER];

			else if( [[words objectAtIndex:0] isEqualToString:PREFS_DELIMITER] )
				[[NSUserDefaults standardUserDefaults] setObject:[words objectAtIndex:1]
														   forKey:PREFS_DELIMITER];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SORTING_MASK] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_SORTING_MASK];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_ITEMS_TABLEVIEW_SIZE] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_ITEMS_TABLEVIEW_SIZE];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_DETAILS_TABLEVIEW_SIZE] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_DETAILS_TABLEVIEW_SIZE];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_MAX_NUMBER_TO_SORT] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_MAX_NUMBER_TO_SORT];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_ALLOW_ROTATION] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														   forKey:PREFS_ALLOW_ROTATION];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_GROUPING_FOR_ITEMS] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_GROUPING_FOR_ITEMS];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_GROUP_NUMBERS] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_GROUP_NUMBERS];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_ENABLE_PHONE_LINKS] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_ENABLE_PHONE_LINKS];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_FIXED_WIDTH] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_FIXED_WIDTH];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_DEFINED_FIXED_WIDTHS] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_DEFINED_FIXED_WIDTHS];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SHOW_STATUS_BAR] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SHOW_STATUS_BAR];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SHOW_DETAILS_TOOLBAR] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SHOW_DETAILS_TOOLBAR];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SAFE_START] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SAFE_START];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_KEEP_QUOTES] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_KEEP_QUOTES];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SHOW_DEBUG_INFO] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SHOW_DEBUG_INFO];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_BLACK_THEME] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_BLACK_THEME];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_CORRECT_PARSING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_CORRECT_PARSING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_CORRECT_SORTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_CORRECT_SORTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_REMOVE_DETAILS_NAVIGATION] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_REMOVE_DETAILS_NAVIGATION];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_DETAILS_SWIPE] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_DETAILS_SWIPE];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_SWIPE_ANIMATION] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_SWIPE_ANIMATION];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SHOW_INLINE_IMAGES] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SHOW_INLINE_IMAGES];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_NUMBER_SENSITIVE_SORTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_NUMBER_SENSITIVE_SORTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_CASE_SENSITIVE_SORTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_CASE_SENSITIVE_SORTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_LITERAL_SORTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_LITERAL_SORTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_MAX_NUMBER_LIVE_FILTER] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														forKey:PREFS_MAX_NUMBER_LIVE_FILTER];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_CONFIRM_LINK] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_CONFIRM_LINK];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_ALIGN_HTML] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_ALIGN_HTML];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_PASSWORD] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_PASSWORD];						
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_HIDE_ADDRESS] )
				[CSVPreferencesController setHideAddress:[[words objectAtIndex:1] boolValue]];
		}
	}
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
