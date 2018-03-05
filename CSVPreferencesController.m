//
//  CSVPreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVPreferencesController.h"
#import "OzymandiasAdditions.h"


@implementation CSVPreferencesController


#define PREFS_ENCODING @"encoding"
#define PREFS_ITEMS_LIST_FONT_SIZE @"itemsListFontSize"
#define PREFS_DETAILS_FONT_SIZE @"detailsFontSize"
#define PREFS_DELIMITER @"delimiter"
#define PREFS_SORTING_MASK @"sortingMask"
#define PREFS_USE_GROUPING_FOR_ITEMS @"useGroupingForItems"
#define PREFS_GROUP_NUMBERS @"groupNumbers"
#define PREFS_ENABLE_PHONE_LINKS @"enablePhoneLinks"
#define PREFS_USE_FIXED_WIDTH @"useFixedWidth"
#define PREFS_DEFINED_FIXED_WIDTHS @"definedFixedWidths"
#define PREFS_SAFE_START @"safeStart"
#define PREFS_KEEP_QUOTES @"keepQuotes"
#define PREFS_SHOW_DEBUG_INFO @"showDebugInfo"
#define PREFS_USE_CORRECT_PARSING @"useCorrectParsing"
#define PREFS_USE_CORRECT_SORTING @"useCorrectSorting"
#define PREFS_SHOW_INLINE_IMAGES @"showInlineImages"
#define PREFS_NUMBER_SENSITIVE_SORTING @"numberSensitiveSorting"
#define PREFS_CASE_SENSITIVE_SORTING @"caseSensitiveSorting"
#define PREFS_LITERAL_SORTING @"literalSorting"
#define PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING @"clearSearchWhenQuickSelecting"
#define PREFS_USE_PASSWORD @"usePassword"
#define PREFS_HAS_BEEN_UPGRADED_TO_CUSTOM_EXTENSION @"hasBeenUpgradedToCustomExtension"
#define PREFS_HAS_SHOWN_HOW_TO @"hasShownHowTo"
#define PREFS_HIDE_ADDRESS @"hideAddress"
#define PREFS_NEXT_DOWNLOAD_TIME @"nextDownloadTime"
#define PREFS_LAST_DOWNLOAD @"lastDownload"
#define PREFS_SIMPLE_MODE @"simpleMode"
#define PREFS_BLANK_WORD_SEPARATOR @"blankWordSeparator"
#define PREFS_MAX_SAFE_BACKGROUND_MINUTES @"maxSafeBackgroundMinutes"
#define LAST_USED_LIST_URL @"lastUsedListURL"
#define PREFS_SYNCHRONIZE_DOWNLOADED_FILES @"synchronizeDownloadedFiles"
#define NEW_FILE_URL @"newFileURL"
#define PREFS_DETAILS_VIEW @"detailsView"
#define PREFS_SHOW_DELETED_COLUMNS @"showDeletedColumns"


NSUInteger sortingMask;
static BOOL reverseItemSorting = FALSE;

+ (void) applicationDidFinishLaunching
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// Clean out old settings
	[defaults removeObjectForKey:@"aboutID"];
	[defaults removeObjectForKey:@"dataID"];
	[defaults removeObjectForKey:@"sortingID"];
	[defaults removeObjectForKey:@"appearanceID"];
    [defaults removeObjectForKey:@"currentPrefsControllerStack"];
    [defaults removeObjectForKey:@"maxNumberLiveFilter"];
    [defaults removeObjectForKey:@"maxNumberOfItemsToSort"];
    [defaults removeObjectForKey:@"searchStringsForFiles"];
    [defaults removeObjectForKey:@"predefinedHiddenColumns"];
    [defaults removeObjectForKey:@"itemPositionsForFiles"];
    [defaults removeObjectForKey:@"useDetailsSwipe"];
    [defaults removeObjectForKey:@"useSwipeAnimation"];
    [defaults removeObjectForKey:@"useDetailsNavigation"];
    [defaults removeObjectForKey:@"alignHtml"];
    [defaults removeObjectForKey:@"tableViewSize"];
    [defaults removeObjectForKey:@"detailsTableViewSize"];
    [defaults removeObjectForKey:@"showDetailsToolbar"];
    [defaults removeObjectForKey:@"confirmLink"];
    [defaults removeObjectForKey:@"enablePhoneLinks"];
    
    if( [defaults objectForKey:@"smartDelimiter"]){
        [defaults removeObjectForKey:@"smartDelimiter"];
        [self setDelimiter:nil];
    }

	// Setup sortingMask
    [self updateSortingMask];    
    
    [self resetDefaultsHaveChanges];
}

+ (void) setDelimiter:(NSString *)delimiter
{
    if( delimiter == nil ){
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_DELIMITER];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setObject:delimiter forKey:PREFS_DELIMITER];
    }
}

+ (NSString *) delimiter
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:PREFS_DELIMITER];
}

+ (BOOL) smartDelimiter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_DELIMITER];
    return obj == nil || [obj isEqualToString:@""];
}

+ (void) setStringEncoding:(NSStringEncoding)encoding
{
    [[NSUserDefaults standardUserDefaults] setInteger:encoding forKey:PREFS_ENCODING];
}

+ (NSStringEncoding) encoding
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ENCODING];
	if( obj )
		return [obj intValue];
	else
		return NSISOLatin1StringEncoding;
}

#define MAX_FONT_SIZE 100
#define MIN_FONT_SIZE 1
#define STANDARD_FONT_SIZE 12

+ (void) setItemsListFontSize:(CGFloat)size
{
    [[NSUserDefaults standardUserDefaults] setDouble:size forKey:PREFS_ITEMS_LIST_FONT_SIZE];
}

+ (CGFloat) itemsListFontSize
{
    CGFloat size = [[NSUserDefaults standardUserDefaults] doubleForKey:PREFS_ITEMS_LIST_FONT_SIZE];
    if( size < MIN_FONT_SIZE)
    {
        size = STANDARD_FONT_SIZE;
    }
    else if( size > MAX_FONT_SIZE)
    {
        size = STANDARD_FONT_SIZE;
    }
    return size;
}

+ (void) increaseItemsListFontSize
{
    [self setItemsListFontSize:[self itemsListFontSize] + 1];
}

+ (void) decreaseItemsListFontSize
{
    [self setItemsListFontSize:[self itemsListFontSize] - 1];
}

+ (BOOL) canIncreaseItemsListFontSize
{
    return [self itemsListFontSize] < MAX_FONT_SIZE;
}

+ (BOOL) canDecreaseItemsListFontSize
{
    return [self itemsListFontSize] > MIN_FONT_SIZE;
}

+ (void) setDetailsFontSize:(CGFloat)size
{
    [[NSUserDefaults standardUserDefaults] setDouble:size forKey:PREFS_DETAILS_FONT_SIZE];
}

+ (CGFloat) detailsFontSize
{
    CGFloat size = [[NSUserDefaults standardUserDefaults] doubleForKey:PREFS_DETAILS_FONT_SIZE];
    if( size < MIN_FONT_SIZE)
    {
        size = STANDARD_FONT_SIZE;
    }
    else if( size > MAX_FONT_SIZE)
    {
        size = STANDARD_FONT_SIZE;
    }
    return size;
}

+ (void) increaseDetailsFontSize
{
    [self setDetailsFontSize:[self detailsFontSize] + 1];
}

+ (void) decreaseDetailsFontSize
{
    [self setDetailsFontSize:[self detailsFontSize] - 1];
}

+ (BOOL) canIncreaseDetailsFontSize
{
    return [self detailsFontSize] < MAX_FONT_SIZE;
}

+ (BOOL) canDecreaseDetailsFontSize
{
    return [self detailsFontSize] > MIN_FONT_SIZE;
}

+ (void) setUseGroupingForItems:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_USE_GROUPING_FOR_ITEMS];
}

+ (BOOL) useGroupingForItems
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_GROUPING_FOR_ITEMS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (void) setGroupNumbers:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_GROUP_NUMBERS];
}

+ (BOOL) groupNumbers
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_GROUP_NUMBERS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (void) setUseFixedWidth:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_USE_FIXED_WIDTH];
}

+ (BOOL) useFixedWidth
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_FIXED_WIDTH];
	if( obj )
		return [obj boolValue];
	else
		return NO;
}

+ (void) setDefinedFixedWidths:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_DEFINED_FIXED_WIDTHS];
}

+ (BOOL) definedFixedWidths
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_DEFINED_FIXED_WIDTHS];
	if( obj )
		return [obj boolValue];
	else
		return NO;
}

+ (void) setKeepQuotes:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_KEEP_QUOTES];
}

+ (BOOL) keepQuotes
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_KEEP_QUOTES];
}

+ (BOOL) showDebugInfo
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_DEBUG_INFO];
}

+ (BOOL) safeStart
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SAFE_START];
}

+ (void) setUseCorrectParsing:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_USE_CORRECT_PARSING];
}

+ (BOOL) useCorrectParsing
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_CORRECT_PARSING];
}

+ (void) setShowInlineImages:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_SHOW_INLINE_IMAGES];
}

+ (BOOL) showInlineImages
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SHOW_INLINE_IMAGES] )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_INLINE_IMAGES];
	else
		return YES;
}

+ (void) setSmartSearchClearing:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
}

+ (BOOL) smartSeachClearing
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
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

+ (NSDate *) nextDownload
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_NEXT_DOWNLOAD_TIME];
	if( obj )
	{
		NSString *time = [[NSUserDefaults standardUserDefaults] stringForKey:PREFS_NEXT_DOWNLOAD_TIME];
		NSArray *split = [time componentsSeparatedByString:@":"];
		if( [split count] == 2 )
		{
			NSDate *now = [NSDate date];
			NSCalendar *current = [NSCalendar currentCalendar];
			NSDateComponents *components = [current components:NSCalendarUnitYear |
											NSCalendarUnitMonth |
											NSCalendarUnitDay
													  fromDate:now];
			[components setHour:[[split objectAtIndex:0] intValue]];
			[components setMinute:[[split objectAtIndex:1] intValue]];
			NSDate *nextDownload = [current dateFromComponents:components];
			if( [nextDownload timeIntervalSinceDate:now] < 0 )
			{
				[components setDay:[components day]+1];
				nextDownload = [current dateFromComponents:components];
			}
			return nextDownload;
		}
	}
		return nil;
}

+ (NSDate *) lastDownload
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_LAST_DOWNLOAD];
	if( [obj isKindOfClass:[NSDate class]] )
		return obj;
	else
		return nil;
}

+ (void) setLastDownload:(NSDate *)lastDownload
{
	[[NSUserDefaults standardUserDefaults] setObject:lastDownload forKey:PREFS_LAST_DOWNLOAD];
}

+ (BOOL) simpleMode
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SIMPLE_MODE];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SIMPLE_MODE];
	else
		return NO;
	
}

+ (void) setBlankWordSeparator:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_BLANK_WORD_SEPARATOR];
}

+ (BOOL) blankWordSeparator
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_BLANK_WORD_SEPARATOR];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_BLANK_WORD_SEPARATOR];
	else
		return NO;	
}

+ (long) maxSafeBackgroundMinutes
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_SAFE_BACKGROUND_MINUTES];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_MAX_SAFE_BACKGROUND_MINUTES];
	else
		return NSIntegerMax;	
}

+ (NSURL *) lastUsedListURL
{
    if( [[NSUserDefaults class] respondsToSelector:@selector(URLForKey:)] )
        return [[NSUserDefaults standardUserDefaults] URLForKey:LAST_USED_LIST_URL];
    else
        return [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:LAST_USED_LIST_URL]];
}

+ (void) setLastUsedListURL:(NSURL *)URL
{
    if( [[NSUserDefaults class] respondsToSelector:@selector(setURL:forKey:)] )
        [[NSUserDefaults standardUserDefaults] setURL:URL forKey:LAST_USED_LIST_URL];
    else
        [[NSUserDefaults standardUserDefaults] setObject:[URL absoluteString] forKey:LAST_USED_LIST_URL];
}

+ (BOOL) synchronizeDownloadedFiles
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SYNCHRONIZE_DOWNLOADED_FILES];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SYNCHRONIZE_DOWNLOADED_FILES];
	else
		return NO;	
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
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_DELIMITER] )
				[[NSUserDefaults standardUserDefaults] setObject:[words objectAtIndex:1]
														   forKey:PREFS_DELIMITER];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SORTING_MASK] )
				[[NSUserDefaults standardUserDefaults] setInteger:[[words objectAtIndex:1] intValue]
														   forKey:PREFS_SORTING_MASK];
			
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
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SAFE_START] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SAFE_START];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_KEEP_QUOTES] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_KEEP_QUOTES];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SHOW_DEBUG_INFO] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SHOW_DEBUG_INFO];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_CORRECT_PARSING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_CORRECT_PARSING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_CORRECT_SORTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_CORRECT_SORTING];
			
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
						
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_CLEAR_SEARCH_WHEN_QUICK_SELECTING];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_USE_PASSWORD] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_USE_PASSWORD];						

			else if( [[words objectAtIndex:0] isEqualToString:PREFS_HIDE_ADDRESS] )
				[CSVPreferencesController setHideAddress:[[words objectAtIndex:1] boolValue]];

			else if( [[words objectAtIndex:0] isEqualToString:PREFS_NEXT_DOWNLOAD_TIME] )
				[[NSUserDefaults standardUserDefaults] setObject:[words objectAtIndex:1]
														  forKey:PREFS_NEXT_DOWNLOAD_TIME];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SIMPLE_MODE] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SIMPLE_MODE];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_BLANK_WORD_SEPARATOR] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_BLANK_WORD_SEPARATOR];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_MAX_SAFE_BACKGROUND_MINUTES] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] integerValue]
														forKey:PREFS_MAX_SAFE_BACKGROUND_MINUTES];
			
			else if( [[words objectAtIndex:0] isEqualToString:PREFS_SYNCHRONIZE_DOWNLOADED_FILES] )
				[[NSUserDefaults standardUserDefaults] setBool:[[words objectAtIndex:1] boolValue]
														forKey:PREFS_SYNCHRONIZE_DOWNLOADED_FILES];
			
		}
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}
				 

+ (BOOL) restrictedDataVersionRunning
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

+ (BOOL) hasShownHowTo
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_HAS_SHOWN_HOW_TO];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_HAS_SHOWN_HOW_TO];
	else
		return NO;
}

+ (void) setHasShownHowTo
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PREFS_HAS_SHOWN_HOW_TO];
}

+ (void) setCaseSensitiveSort:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_CASE_SENSITIVE_SORTING];
    [self updateSortingMask];
}
+ (BOOL) caseSensitiveSort
{
    id obj;
    obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_CASE_SENSITIVE_SORTING];
    if( obj )
        return [obj boolValue];
    else
        return FALSE;
}

+ (void) setNumericSort:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_NUMBER_SENSITIVE_SORTING];
    [self updateSortingMask];
}

+ (BOOL) numericSort
{
    id obj;
    obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_NUMBER_SENSITIVE_SORTING];
    if( obj )
        return [obj boolValue];
    else
        return TRUE;
}

+ (void) setLiteralSort:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_LITERAL_SORTING];
    [self updateSortingMask];
}

+ (BOOL) literalSort
{
    id obj;
    obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_LITERAL_SORTING];
    if( obj )
        return [obj boolValue];
    else
        return TRUE;
}

+ (void) setCorrectSort:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_USE_CORRECT_SORTING];
}

+ (BOOL) correctSort
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_USE_CORRECT_SORTING];
}

+ (void) updateSortingMask
{
    // Default, so make sure default return values above correlates to these defaults
    sortingMask = 0;
    if( ![self caseSensitiveSort])
        sortingMask ^= NSCaseInsensitiveSearch;
    if( [self numericSort])
        sortingMask ^= NSNumericSearch;
    if( [self literalSort])
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



+ (void) toggleReverseItemSorting
{
    reverseItemSorting = !reverseItemSorting;
}

+ (BOOL) reverseItemSorting
{
    return reverseItemSorting;
}

+ (NSString *) lastUsedURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NEW_FILE_URL];
}

+ (void) setLastUsedURL:(NSString *)URL
{
    if( URL )
    {
        [[NSUserDefaults standardUserDefaults] setObject:URL
                                                  forKey:NEW_FILE_URL];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:NEW_FILE_URL];
    }
}

+ (NSInteger) selectedDetailsView
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_DETAILS_VIEW];
}

+ (void) setSelectedDetailsView:(NSInteger)view
{
    [[NSUserDefaults standardUserDefaults] setInteger:view forKey:PREFS_DETAILS_VIEW];
}

+ (BOOL) showDeletedColumns
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_DELETED_COLUMNS];
}

+ (void) setShowDeletedColumns:(BOOL)yn
{
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:PREFS_SHOW_DELETED_COLUMNS];
}

static NSDictionary *oldDefaults = nil;

+ (BOOL) defaultsHaveChanged
{
    return ![[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] isEqual:oldDefaults];
}

+ (void) resetDefaultsHaveChanges
{
    oldDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] copy];
}


@end
