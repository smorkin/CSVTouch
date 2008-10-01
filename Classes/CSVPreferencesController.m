//
//  CSVPreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVPreferencesController.h"
#import "CSVDataViewController.h"
#import "OzyRotatableViewController.h"
#import "OzyTableViewController.h"
#import "OzymandiasAdditions.h"


static CSVPreferencesController *sharedInstance = nil;

@implementation CSVPreferencesController

+ (CSVPreferencesController *) sharedInstance
{
	return sharedInstance;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if( [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(allowRotation)] )
		return [(id <OzymandiasApplicationDelegate>)[[UIApplication sharedApplication] delegate] allowRotation];
	else
		return YES;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if( section == 0 )
		return 1;
	else
		return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"preferenceControllerCellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if( indexPath.section == 0 )
	{
		if( indexPath.row == 0 )
			cell.text = @"About";
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.section == 0 )
	{
		if( indexPath.row == 0 )
			[self pushViewController:aboutController animated:YES];
	}
}
	
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if( section == 0 )
		return @"Documentation";
	else if( section == 1 )
		return @"Preferences";
	else
		return @"";
}

@end

@implementation CSVPreferencesController (PreferenceData)

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


- (void) loadPreferences
{
//	[sizeControl setTitle:@"Normal" forSegmentAtIndex:0];
//	[sizeControl insertSegmentWithTitle:@"Small" atIndex:1 animated:NO];
//	[sizeControl insertSegmentWithTitle:@"Mini" atIndex:2 animated:NO];
//	sizeControl.selectedSegmentIndex = [CSVPreferencesController tableViewSize];
}

#define ABOUT_ID @"aboutID"
#define DATA_ID @"dataID"
#define SORTING_ID @"sortingID"
#define APPEARANCE_ID @"appearanceID"

#define DEFS_CURRENT_PREFS_CONTROLLER_STACK @"currentPrefsControllerStack"

- (NSString *) idForController:(UIViewController *)controller
{
	if( controller == aboutController )
		return ABOUT_ID;
	else
		return @"";
}

- (UIViewController *) controllerForId:(NSString *) controllerId
{
	if( [controllerId isEqualToString:ABOUT_ID] )
		return aboutController;
	else
		return nil;	
}

static BOOL startupInProgress = NO;

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL)emergencyMode
{
	startupInProgress = TRUE;
	[self pushViewController:prefsSelectionController animated:NO];

	[CSVPreferencesController updateSortingMask];
	
	NSArray *controllerStack = [[NSUserDefaults standardUserDefaults] objectForKey:DEFS_CURRENT_PREFS_CONTROLLER_STACK];
	for( NSString *controllerId in controllerStack )
	{
		UIViewController *controller = [self controllerForId:controllerId];
		if( controller )
			[self pushViewController:controller animated:NO];
	}
	
	[self loadPreferences];
	startupInProgress = FALSE;
}

- (void) applicationWillTerminate
{
	NSMutableArray *controllerStack = [NSMutableArray array];
	for( UIViewController *controller in [self viewControllers] )
		[controllerStack addObject:[self idForController:controller]];
	[[NSUserDefaults standardUserDefaults] setObject:controllerStack forKey:DEFS_CURRENT_PREFS_CONTROLLER_STACK];	
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	sharedInstance = self;
	return self;
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

//+ (void) setSmartDelimiter:(BOOL)useSmart
//{
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	[defaults setBool:useSmart forKey:PREFS_SMART_DELIMITER];
//}
//
+ (NSInteger) tableViewSize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger s = [defaults integerForKey:PREFS_TABLEVIEW_SIZE];
	if( s < 0 || s > OZY_MINI )
		return OZY_MINI;
	else
		return s;
}

//+ (void) setTableViewSize:(int)size
//{
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	[defaults setInteger:size
//				 forKey:PREFS_TABLEVIEW_SIZE];
//}

+ (NSUInteger) maxNumberOfItemsToSort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_MAX_NUMBER_TO_SORT];
}	

+ (void) setMaxNumberOfItemsToSort:(int) newValue
{
	NSUInteger oldValue = [CSVPreferencesController maxNumberOfItemsToSort];
	if( oldValue != newValue && newValue >= 0 )
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:newValue forKey:PREFS_MAX_NUMBER_TO_SORT];
		if( newValue == 0 || newValue > oldValue )
			[[CSVDataViewController sharedInstance] resortObjects];
	}	
}

+ (NSStringEncoding) encoding
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_ENCODING];
	if( obj )
		return [obj intValue];
	else
		return NSISOLatin1StringEncoding;
}

+ (void) setEncoding:(NSStringEncoding)encoding
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", encoding] forKey:PREFS_ENCODING];
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


NSUInteger sortingMask;

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

- (void) showAlertAboutChangedPrefs:(NSString *) msg
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Restart required"
													message:msg
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil] autorelease];
	[alert show];	
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
