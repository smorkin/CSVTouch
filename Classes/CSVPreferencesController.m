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
#define PREFS_TABLEVIEW_SIZE @"tableViewSize"
#define PREFS_MAX_NUMBER_TO_SORT @"maxNumberOfItemsToSort"
#define PREFS_ALLOW_ROTATION @"allowRotation"
#define PREFS_USE_GROUPING_FOR_ITEMS @"useGroupingForItems"
#define PREFS_SHOW_STATUS_BAR @"showStatusBar"
#define PREFS_SAFE_START @"safeStart"
#define PREFS_KEEP_QUOTES @"keepQuotes"
#define PREFS_SHOW_DEBUG_INFO @"showDebugInfo"
#define PREFS_USE_BLACK_THEME @"useBlackTheme"
#define PREFS_USE_CORRECT_PARSING @"useCorrectParsing"
#define PREFS_USE_CORRECT_SORTING @"useCorrectSorting"
#define PREFS_REMOVE_DETAILS_NAVIGATION @"useDetailsNavigation"
#define PREFS_SHOW_INLINE_IMAGES @"showInlineImages"
#define PREFS_NUMBER_SENSITIVE_SORTING @"numberSensitiveSorting"
#define PREFS_CASE_SENSITIVE_SORTING @"caseSensitiveSorting"
#define PREFS_LITERAL_SORTING @"literalSorting"


NSUInteger sortingMask;

//- (void) loadPreferences
//{
//	[sizeControl setTitle:@"Normal" forSegmentAtIndex:0];
//	[sizeControl insertSegmentWithTitle:@"Small" atIndex:1 animated:NO];
//	[sizeControl insertSegmentWithTitle:@"Mini" atIndex:2 animated:NO];
//	sizeControl.selectedSegmentIndex = [CSVPreferencesController tableViewSize];
//}



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

//+ (void) setDelimiter:(NSString *)s
//{
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	[defaults setObject:s forKey:PREFS_DELIMITER];
//}
//
+ (BOOL) smartDelimiter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SMART_DELIMITER];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SMART_DELIMITER];
	else
		return YES;
}

+ (NSInteger) tableViewSize
{
	NSInteger s = [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_TABLEVIEW_SIZE];
	if( s < 0 || s > OZY_MINI )
		return OZY_SMALL;
	else
		return s;
}

+ (BOOL) modifyTableViewSize:(BOOL)increase
{
	int newSize = [self tableViewSize];
	
	// Stupidly enough the sizes go backwards...
	if( increase) 
		newSize--;
	else
		newSize++;
	if( newSize >= OZY_NORMAL && newSize <= OZY_MINI )
	{
		[[NSUserDefaults standardUserDefaults] setInteger:newSize
												   forKey:PREFS_TABLEVIEW_SIZE];
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

+ (BOOL) showInlineImages
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SHOW_INLINE_IMAGES] )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_INLINE_IMAGES];
	else
		return YES;
}



+ (void) updateSortingMask
{
	sortingMask = NSNumericSearch ^ NSCaseInsensitiveSearch;
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
