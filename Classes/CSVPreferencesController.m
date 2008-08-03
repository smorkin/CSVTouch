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

@interface OzyEncodingItem : NSObject
{
	NSString *_userDescription;
	NSStringEncoding _encoding;
	CGFloat _width;
}
@property (nonatomic, copy) NSString *userDescription;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) CGFloat width;

+ (NSArray *) availableEncodings;
+ (NSString *) userDescriptionForEncoding:(NSStringEncoding) encoding;
+ (NSStringEncoding) encodingForUserDescription:(NSString *) userDescription;
@end

@implementation OzyEncodingItem
@synthesize userDescription = _userDescription;
@synthesize encoding = _encoding;
@synthesize width = _width;

- (id) initWithUserDescription:(NSString *)s encoding:(NSStringEncoding)enc width:(CGFloat)w
{
	self = [super init];
	self.userDescription = s;
	self.encoding = enc;
	self.width = w;
	return self;
}

+ (NSArray *) availableEncodings
{
	static NSMutableArray *items = nil;
	
	if( !items )
	{
		items = [[NSMutableArray alloc] init];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"UTF8" 
																  encoding:NSUTF8StringEncoding
																	 width:0.0] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Unicode" 
																  encoding:NSUnicodeStringEncoding
																	 width:85] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Latin1" 
																  encoding:NSISOLatin1StringEncoding
																	 width:75] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Mac" 
																  encoding:NSMacOSRomanStringEncoding
																	 width:0.0] autorelease]];
	}
	
	return items;
}

+ (NSString *) userDescriptionForEncoding:(NSStringEncoding) encoding
{
	for( OzyEncodingItem *item in [self availableEncodings] )
		if( item.encoding == encoding)
			return item.userDescription;
	return @"";
}

+ (NSStringEncoding) encodingForUserDescription:(NSString *) userDescription
{
	for( OzyEncodingItem *item in [self availableEncodings] )
		if( [item.userDescription isEqualToString:userDescription] )
			return item.encoding;
	return NSUTF8StringEncoding;
}

@end

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
	return 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if( section == 0 )
		return 2;
	else
		return 3;
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
		else if( indexPath.row == 1 )
			cell.text = @"Legal";
	}
	else
	{
		if( indexPath.row == 0 )
			cell.text = @"Data";
		else if( indexPath.row == 1 )
			cell.text = @"Sorting";
		else if( indexPath.row == 2 )
			cell.text = @"Appearance";
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.section == 0 )
	{
		if( indexPath.row == 0 )
			[self pushViewController:aboutController animated:YES];
		else if( indexPath.row == 1 )
			[self pushViewController:legalController animated:YES];
	}
	else
	{
		if( indexPath.row == 0 )
			[self pushViewController:dataPrefsController animated:YES];
		else if( indexPath.row == 1 )
			[self pushViewController:sortingPrefsController animated:YES];
		else if( indexPath.row == 2 )
			[self pushViewController:appearancePrefsController animated:YES];
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
#define PREFS_MAX_NUMBER_TO_SORT @"maxNumberOfObjectsToSort"
#define PREFS_ALLOW_ROTATION @"allowRotation"
#define PREFS_USE_GROUPING_FOR_ITEMS @"useGroupingForItems"
#define PREFS_SHOW_STATUS_BAR @"showStatusBar"
#define PREFS_SHOW_INLINE_PREFERENCES @"showInlinePreferences"
#define PREFS_SAFE_START @"safeStart"

- (void) loadPreferences
{
	[sizeControl setTitle:@"Normal" forSegmentAtIndex:0];
	[sizeControl insertSegmentWithTitle:@"Small" atIndex:1 animated:NO];
	[sizeControl insertSegmentWithTitle:@"Mini" atIndex:2 animated:NO];
	sizeControl.selectedSegmentIndex = [CSVPreferencesController tableViewSize];
	
	[delimiterControl setTitle:@"," forSegmentAtIndex:0];
	[delimiterControl insertSegmentWithTitle:@";" atIndex:1 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"." atIndex:2 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"|" atIndex:3 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"space" atIndex:4 animated:NO];
	[delimiterControl setWidth:80 forSegmentAtIndex:4];  
	[delimiterControl insertSegmentWithTitle:@"tab" atIndex:5 animated:NO];
	[delimiterControl setWidth:60 forSegmentAtIndex:5];
	NSString *delimiter = [CSVPreferencesController delimiter];
	if( [delimiter isEqualToString:@","] )
		delimiterControl.selectedSegmentIndex = 0;
	else if( [delimiter isEqualToString:@";"] )
		delimiterControl.selectedSegmentIndex = 1;
	else if( [delimiter isEqualToString:@"."] )
		delimiterControl.selectedSegmentIndex = 2;
	else if( [delimiter isEqualToString:@"|"] )
		delimiterControl.selectedSegmentIndex = 3;
	else if( [delimiter isEqualToString:@" "] )
		delimiterControl.selectedSegmentIndex = 4;
	else if( [delimiter isEqualToString:@"\t"] )
		delimiterControl.selectedSegmentIndex = 5;
	//	[delimiterControl setEnabled:![self smartDelimiter]];
	delimiterControl.hidden = [CSVPreferencesController smartDelimiter];
	
	[smartDelimiterSwitch setOn:[CSVPreferencesController smartDelimiter] animated:NO];
	
	NSString *userDescription = [OzyEncodingItem userDescriptionForEncoding:[CSVPreferencesController encoding]];
	NSArray *encodings = [OzyEncodingItem availableEncodings];
	OzyEncodingItem *item;
	for( NSUInteger i = 0 ; i < [encodings count] ; i++ )
	{
		item = [encodings objectAtIndex:i];
		if( i == 0 )
			[encodingControl setTitle:item.userDescription forSegmentAtIndex:0];
		else
			[encodingControl insertSegmentWithTitle:item.userDescription atIndex:i animated:NO];
		[encodingControl setWidth:item.width forSegmentAtIndex:i];
		if( [userDescription isEqualToString:item.userDescription] )
			encodingControl.selectedSegmentIndex = i;
	}
	
	NSString *sorting = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SORTING_MASK];
	if( sorting )
		sortingMask = [sorting intValue];
	else
		sortingMask = 0;
	[numericCompareSwitch setOn:((sortingMask & NSNumericSearch) != 0) animated:NO];
	[caseSensitiveCompareSwitch setOn:((sortingMask & NSCaseInsensitiveSearch) == 0) animated:NO];
	
	maxNumberOfObjectsToSort.text = [NSString stringWithFormat:@"%d", [CSVPreferencesController maxNumberOfObjectsToSort]];	
	allowRotatableInterface.on = [CSVPreferencesController allowRotatableInterface];
	useGroupingForItems.on = [CSVPreferencesController useGroupingForItems];
	showStatusBar.on = [CSVPreferencesController showStatusBar];
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
	else if( controller == dataPrefsController )
		return DATA_ID;
	else if( controller == sortingPrefsController )
		return SORTING_ID;
	else if( controller == appearancePrefsController )
		return APPEARANCE_ID;
	else
		return @"";
}

- (UIViewController *) controllerForId:(NSString *) controllerId
{
	if( [controllerId isEqualToString:ABOUT_ID] )
		return aboutController;
	else if( [controllerId isEqualToString:DATA_ID] )
		return dataPrefsController;
	else if( [controllerId isEqualToString:SORTING_ID] )
		return sortingPrefsController;
	else if( [controllerId isEqualToString:APPEARANCE_ID] )
		return appearancePrefsController;
	else
		return nil;	
}

static BOOL startupInProgress = NO;

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL)emergencyMode
{
	startupInProgress = TRUE;
	[self pushViewController:prefsSelectionController animated:NO];

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

+ (void) setDelimiter:(NSString *)s
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:s forKey:PREFS_DELIMITER];
}

+ (BOOL) smartDelimiter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SMART_DELIMITER];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SMART_DELIMITER];
	else
		return YES;
}

+ (void) setSmartDelimiter:(BOOL)useSmart
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:useSmart forKey:PREFS_SMART_DELIMITER];
}

+ (NSInteger) tableViewSize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger s = [defaults integerForKey:PREFS_TABLEVIEW_SIZE];
	if( s < 0 || s > OZY_MINI )
		return OZY_MINI;
	else
		return s;
}

// Note that we use setObject here instead of setInteger.
// Reason: We might want a different default value than 0.
+ (void) setTableViewSize:(int)size
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInt:size]
				 forKey:PREFS_TABLEVIEW_SIZE];
}

+ (NSUInteger) maxNumberOfObjectsToSort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_MAX_NUMBER_TO_SORT];
}	

+ (void) setMaxNumberOfObjectsToSort:(int) newValue
{
	NSUInteger oldValue = [CSVPreferencesController maxNumberOfObjectsToSort];
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
		return NSUTF8StringEncoding;
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

+ (void) setAllowRotatableInterface:(BOOL)allowRotation
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:allowRotation] forKey:PREFS_ALLOW_ROTATION];
}

static BOOL useGroupingForItemsHasChangedSinceStart = NO;

+ (BOOL) useGroupingForItemsHasChangedSinceStart
{
	return useGroupingForItemsHasChangedSinceStart;
}

+ (BOOL) useGroupingForItems
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_USE_GROUPING_FOR_ITEMS];
	if( obj )
		return [obj boolValue];
	else
		return YES;
}

+ (void) setUseGroupingForItems:(BOOL)useGrouping
{
	if( [self useGroupingForItems] != useGrouping )
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:useGrouping]
												  forKey:PREFS_USE_GROUPING_FOR_ITEMS];
		useGroupingForItemsHasChangedSinceStart = !useGroupingForItemsHasChangedSinceStart;
		// Note that the toggling above makes sure that if the user changes the value twice,
		// we don't consider the value to have been changed. This is correct since
	}
}

+ (BOOL) showStatusBar
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_SHOW_STATUS_BAR];
}

+ (void) setShowStatusBar:(BOOL)shouldShow
{
	if( [self showStatusBar] != shouldShow )
	{
		[[NSUserDefaults standardUserDefaults] setBool:shouldShow
												forKey:PREFS_SHOW_STATUS_BAR];
	}
}

NSUInteger sortingMask;

+ (NSUInteger) sortingMask
{
	NSString *sorting = [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_SORTING_MASK];
	if( sorting )
		sortingMask = [sorting intValue];
	else
		sortingMask = 0;
	return sortingMask;
}

+ (void) setSortingMask:(int)mask
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", mask] forKey:PREFS_SORTING_MASK];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if( textField == maxNumberOfObjectsToSort )
	{
		[maxNumberOfObjectsToSort endEditing:YES];
		NSUInteger oldValue = [CSVPreferencesController maxNumberOfObjectsToSort];
		NSUInteger newValue = [maxNumberOfObjectsToSort.text intValue];
		if( oldValue != newValue && newValue >= 0 )
		{
			[CSVPreferencesController setMaxNumberOfObjectsToSort:newValue];
			if( newValue == 0 || newValue > oldValue )
				[[CSVDataViewController sharedInstance] resortObjects];
		}	
	}
	return YES;
}

- (IBAction) sizeControlChanged:(id)sender
{
	[CSVPreferencesController setTableViewSize:[sizeControl selectedSegmentIndex]];
	[[CSVDataViewController sharedInstance] setSize:[sizeControl selectedSegmentIndex]];
}

- (IBAction) delimiterControlChanged:(id)sender
{
	switch( [delimiterControl selectedSegmentIndex] )
	{
		case 0:
			[CSVPreferencesController setDelimiter:@","];
			break;
		case 1:
			[CSVPreferencesController setDelimiter:@";"];
			break;
		case 2:
			[CSVPreferencesController setDelimiter:@"."];
			break;
		case 3:
			[CSVPreferencesController setDelimiter:@"|"];
			break;
		case 4:
			[CSVPreferencesController setDelimiter:@" "];
			break;
		case 5:
			[CSVPreferencesController setDelimiter:@"\t"];
			break;
		default:
			break;
	}
	[CSVPreferencesController setSmartDelimiter:[smartDelimiterSwitch isOn]];
	//	[delimiterControl setEnabled:![self smartDelimiter]];
	delimiterControl.hidden = [CSVPreferencesController smartDelimiter];
	[[CSVDataViewController sharedInstance] reparseFiles];
}

- (IBAction) encodingControlChanged:(id)sender
{
	NSStringEncoding encoding = [OzyEncodingItem encodingForUserDescription:
								 [encodingControl titleForSegmentAtIndex:[encodingControl selectedSegmentIndex]]];
	[CSVPreferencesController setEncoding:encoding];
	if( !startupInProgress )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart required"
														message:@"Files you have looked at won't update until after restarting"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction) sortingChanged:(id)sender
{
	sortingMask = NSCaseInsensitiveSearch;
	if( [numericCompareSwitch isOn] )
		sortingMask ^= NSNumericSearch;
	if( [caseSensitiveCompareSwitch isOn] )
		sortingMask ^= NSCaseInsensitiveSearch;
	[CSVPreferencesController setSortingMask:sortingMask];
	[[CSVDataViewController sharedInstance] resortObjects];
}	

- (IBAction) rotationChanged:(id)sender
{
	[CSVPreferencesController setAllowRotatableInterface:[allowRotatableInterface isOn]];
}

- (IBAction) groupingChanged:(id)sender
{
	[CSVPreferencesController setUseGroupingForItems:[useGroupingForItems isOn]];
	if( !startupInProgress )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart required"
														message:@"This change won't take effect until you restart"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction) showStatusBarChanged:(id)sender
{
	[CSVPreferencesController setShowStatusBar:[showStatusBar isOn]];
	if( !startupInProgress )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart required"
														message:@"This change won't take effect until you restart"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

@end
