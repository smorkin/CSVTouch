//
//  CSVDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVDataViewController.h"
#import "OzyTableViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "CSVPreferencesController.h"
#import "CSVFileParser.h"
#import "CSVRow.h"
#import "OzyTextViewController.h"
#import "OzymandiasAdditions.h"

#define FILES_ID @"filesID"
#define OBJECTS_ID @"objectsID"
#define DETAILS_ID @"detailsID"

@interface NSString (FancyDetailsComparison)
- (NSComparisonResult) compareFancyDetails:(NSString *)s;
@end

@implementation NSString (FancyDetailsComparison)
- (NSComparisonResult) compareFancyDetails:(NSString *)s
{
	return [self compare:s options:sortingMask];
}
@end

@implementation CSVDataViewController

- (CSVFileParser *) currentFile
{
	return currentFile;
}

- (void) refreshObjectsWithResorting:(BOOL)needsResorting
{
	NSMutableArray *allObjects = [currentFile itemsWithResetShortdescriptions:needsResorting];
	NSMutableArray *filteredObjects = [NSMutableArray array];
	NSMutableArray *workObjects;
	NSString *searchString = [[searchBar text] lowercaseString];
	
	// We should always resort all objects, no matter which are actually shown
	if( needsResorting &&
	   ([CSVPreferencesController maxNumberOfObjectsToSort] == 0 ||
		[allObjects count] <= [CSVPreferencesController maxNumberOfObjectsToSort]) )
	{
		[allObjects sortUsingSelector:@selector(compareShort:)];
		currentFile.hasBeenSorted = YES;
	}
	
	if( searchString && ![searchString isEqualToString:@""] )
	{
		NSArray *words = [searchString componentsSeparatedByString:@" "];
		NSUInteger wordCount = [words count];
		NSUInteger wordNr;
		NSString *objectDescription;
		for( CSVRow *row in allObjects )
		{
			objectDescription = [[row shortDescription] lowercaseString];
			for( wordNr = 0 ;
				wordNr < wordCount && [objectDescription rangeOfString:[words objectAtIndex:wordNr]].length > 0; 
				wordNr++ );
				if( wordNr == wordCount )
					[filteredObjects addObject:row];
		}
		workObjects = filteredObjects;
	}
	else
	{
		workObjects = allObjects;
	}
	
	[itemController setObjects:workObjects];
	[itemController dataLoaded];
}

- (NSArray *) columnIndexes
{
	return columnIndexes;
}

- (int *) rawColumnIndexes
{
	return rawColumnIndexes;
}

- (void) updateColumnIndexes
{
	NSArray *availableColumns = [currentFile availableColumnNames];
	[columnIndexes removeAllObjects];
	if( rawColumnIndexes )
		free(rawColumnIndexes);
	for( NSString *usedColumn in [editController objects] )
	{
		for( NSUInteger i = 0 ; i < [availableColumns count] ; i++ )
			if( [usedColumn isEqualToString:[availableColumns objectAtIndex:i]] )
				[columnIndexes addObject:[NSNumber numberWithInt:i]];
	}
	rawColumnIndexes = malloc(sizeof(int) * [columnIndexes count]);
	for( int i = 0 ; i < [columnIndexes count] ; i++ )
		rawColumnIndexes[i] = [[columnIndexes objectAtIndex:i] intValue];
}

- (void) updateColumnNames
{
	NSArray *names = [columnNamesForFileName objectForKey:[currentFile fileName]];
	if( !names )
		names = [currentFile availableColumnNames];
	[editController setObjects:[NSMutableArray arrayWithArray:names]];
	[editController dataLoaded];
	[self updateColumnIndexes];
}

- (void) cacheCurrentFileData
{
	if( currentFile )
	{
		NSArray *a = [[itemController tableView] indexPathsForVisibleRows];
		if( [a count] > 0 )
			[indexPathForFileName setObject:[[a objectAtIndex:0] dictionaryRepresentation] forKey:[currentFile fileName]];
		else
			[indexPathForFileName removeObjectForKey:[currentFile fileName]];
		if( searchBar.text && ![searchBar.text isEqualToString:@""] )
			[searchStringForFileName setObject:searchBar.text forKey:[currentFile fileName]];
		else
			[searchStringForFileName removeObjectForKey:[currentFile fileName]];
	}
}	
	
//- (UIViewController *) currentDetailsController
//{
//	if( [CSVPreferencesController useSimpleDetailsView] )
//		return detailsController;
//	else
//		return fancyDetailsController;
//}
//
- (void) selectFile:(CSVFileParser *)file
{		
	// Store current position of itemController and search string
	[self cacheCurrentFileData];
		
	[currentFile release];
	currentFile = [file retain];
	[currentFile parseIfNecessary];
	NSString *cachedSearchString = [searchStringForFileName objectForKey:[currentFile fileName]];
	if( cachedSearchString )
		searchBar.text = cachedSearchString;
	else
		searchBar.text = @"";
	[self updateColumnNames];
	[itemController setTitle:[file tableViewDescription]];
	[self refreshObjectsWithResorting:!currentFile.hasBeenSorted];
	
	// Reset last known position of items
	// First scroll to top, if we don't find any setting
	[itemController.tableView scrollToTopWithAnimation:NO];
	NSDictionary *indexPathDictionary = [indexPathForFileName objectForKey:[currentFile fileName]];
	if( [indexPathDictionary isKindOfClass:[NSDictionary class]] )
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathWithDictionary:indexPathDictionary];
		if( [itemController itemExistsAtIndexPath:indexPath] )
	   {
		   [[itemController tableView] scrollToRowAtIndexPath:indexPath
											 atScrollPosition:UITableViewScrollPositionTop
													 animated:NO];
	   }
	}
}

- (void) updateBadgeValueUsingItem:(UINavigationItem *)item push:(BOOL)push
{
	NSUInteger count = 0;
	NSString *addString = @"";
	
	// Row or details controller will be visible
	if((push && item == itemController.navigationItem) || 
	   (item == detailsController.navigationItem) ||
		(item == fancyDetailsController.navigationItem))
	{
		count = [[itemController objects] count];
		if( count != [[currentFile itemsWithResetShortdescriptions:NO] count] )
			addString = [NSString stringWithFormat:@"/%d", [[currentFile itemsWithResetShortdescriptions:NO] count]];
		self.tabBarItem.title = @"Items";
	}
	// File controller will be visible (or parseErrorController involved, in which case always use Files data)
	else if((!push && item == itemController.navigationItem) ||
			(push && item == fileController.navigationItem) ||
			(item == parseErrorController.navigationItem))
	{
		count = [[fileController objects] count];
		self.tabBarItem.title = @"Files";
	}

	if( count != 0 )
		self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d%@", count, addString];
	else
		self.tabBarItem.badgeValue = nil;
}

- (void) selectDetailsForRow:(NSUInteger)row
{
	// First simple details view
	if( [[itemController objects] count] > row )
		[[detailsController textView] setText:[(CSVRow *)[[itemController objects] objectAtIndex:row] longDescription]];
	else
		[[detailsController textView] setText:@"No data found!"];
	
	// Then fancy view
	NSMutableArray *items = [(CSVRow *)[[itemController objects] objectAtIndex:row] longDescriptionInArray];
	[items sortUsingSelector:@selector(compareFancyDetails:)];
	fancyDetailsController.objects = items;
	fancyDetailsController.removeDisclosure = YES;
	[fancyDetailsController dataLoaded];
}

- (NSString *) idForController:(UIViewController *)controller
{
	if( controller == fileController )
		return FILES_ID;
	else if( controller == itemController )
		return OBJECTS_ID;
	else if( controller == fancyDetailsController || controller == detailsController )
		return DETAILS_ID;
	else
		return @"";
}

- (UIViewController *) controllerForId:(NSString *) controllerId
{
	if( [controllerId isEqualToString:FILES_ID] )
		return fileController;
	else if( [controllerId isEqualToString:OBJECTS_ID] )
		return itemController;
	else if( [controllerId isEqualToString:DETAILS_ID] )
		return fancyDetailsController;
	else
		return nil;	
}

#define DEFS_COLUMN_NAMES @"defaultColumnNames"
#define DEFS_CURRENT_FILE @"currentFile"
#define DEFS_CURRENT_CONTROLLER_STACK @"currentControllerStack"
#define DEFS_INDEX_PATH @"indexPath"
#define DEFS_ITEM_POSITIONS_FOR_FILES @"itemPositionsForFiles"
#define DEFS_SEARCH_STRINGS_FOR_FILES @"searchStringsForFiles"

- (void) applicationWillTerminate
{
	[self cacheCurrentFileData];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( columnNamesForFileName )
	{
		[defaults setObject:columnNamesForFileName forKey:DEFS_COLUMN_NAMES];
	}
	
	if( indexPathForFileName && ![CSVPreferencesController useGroupingForItemsHasChangedSinceStart] )
	{
		[defaults setObject:indexPathForFileName forKey:DEFS_ITEM_POSITIONS_FOR_FILES];
	}
	else
	{
		[defaults removeObjectForKey:DEFS_ITEM_POSITIONS_FOR_FILES];
	}
	
	if( searchStringForFileName )
	{
		[defaults setObject:searchStringForFileName forKey:DEFS_SEARCH_STRINGS_FOR_FILES];
	}
	
	if( [self topViewController] != fileController )
		[defaults setObject:[currentFile fileName] forKey:DEFS_CURRENT_FILE];
	else
		[defaults removeObjectForKey:DEFS_CURRENT_FILE];
	
	NSMutableArray *controllerStack = [NSMutableArray array];
	for( UIViewController *controller in [self viewControllers] )
		[controllerStack addObject:[self idForController:controller]];
	[defaults setObject:controllerStack forKey:DEFS_CURRENT_CONTROLLER_STACK];
	
	if( [self topViewController] == detailsController || [self topViewController] == fancyDetailsController )
	{
		if( ![CSVPreferencesController useGroupingForItemsHasChangedSinceStart] )
			[defaults setObject:[[[itemController tableView] indexPathForSelectedRow] dictionaryRepresentation]
						 forKey:DEFS_INDEX_PATH];
		else
			[defaults removeObjectForKey:DEFS_INDEX_PATH];
	}
	else if( [self topViewController] == itemController )
	{
		NSArray *a = [[itemController tableView] indexPathsForVisibleRows];
		if( [a count] > 0 && ![CSVPreferencesController useGroupingForItemsHasChangedSinceStart] )
			[defaults setObject:[[a objectAtIndex:0] dictionaryRepresentation] forKey:DEFS_INDEX_PATH];
		else
			[defaults removeObjectForKey:DEFS_INDEX_PATH];
	}
	else if( [self topViewController] == fileController )
	{
		NSArray *a = [[fileController tableView] indexPathsForVisibleRows];
		if( [a count] > 0 )
			[defaults setObject:[[a objectAtIndex:0] dictionaryRepresentation] forKey:DEFS_INDEX_PATH];
		else
			[defaults removeObjectForKey:DEFS_INDEX_PATH];
	}
	else
	{
		[defaults removeObjectForKey:DEFS_INDEX_PATH];
	}
		
	[defaults synchronize];
}

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL)emergencyMode
{	
	// Setup stuff for controllers which can't be configured using InterfaceBuilder
	[[editController tableView] setEditing:YES animated:NO];
	editController.editable = YES;
	editController.size = OZY_NORMAL;
	editController.titleForSingleSection = @"Select & Arrange Columns";
	fileController.editable = YES;
	fileController.size = OZY_NORMAL;
	itemController.editable = NO;
	itemController.size = [CSVPreferencesController tableViewSize];
	itemController.useIndexes = [CSVPreferencesController useGroupingForItems];
	fancyDetailsController.size = [CSVPreferencesController tableViewSize];
		
	// Autocorrection of searching should be off
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;

	// Push the fileController to the root of the navigation;
	// we must do this in case we have no saved navigationstack
	[self pushViewController:fileController animated:NO];
	[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
	
	// Read last state to be able to get back to where we were before quitting last time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// 1. Read in the saved columns & order of them for each file; similarly for search strings & positions
	NSDictionary *defaultNames = [defaults objectForKey:DEFS_COLUMN_NAMES];
	if( defaultNames && [defaultNames isKindOfClass:[NSDictionary class]] )
	{
		[columnNamesForFileName release];
		columnNamesForFileName = [[NSMutableDictionary alloc] initWithDictionary:defaultNames];
	}
	NSDictionary *itemPositions = [defaults objectForKey:DEFS_ITEM_POSITIONS_FOR_FILES];
	if( itemPositions && [itemPositions isKindOfClass:[NSDictionary class]] )
	{
		[indexPathForFileName release];
		indexPathForFileName = [[NSMutableDictionary alloc] initWithDictionary:itemPositions];
	}
	NSDictionary *searchStrings = [defaults objectForKey:DEFS_SEARCH_STRINGS_FOR_FILES];
	if( searchStrings && [searchStrings isKindOfClass:[NSDictionary class]] )
	{
		[searchStringForFileName release];
		searchStringForFileName = [[NSMutableDictionary alloc] initWithDictionary:searchStrings];
	}
	
	// If starting up in emergency mode, we should not do anything more here
	if( emergencyMode )
		return;
	
	// 2. Read in the saved current file
	NSString *fileName = [defaults objectForKey:DEFS_CURRENT_FILE];
	for( CSVFileParser *file in [fileController objects] )
	{
		if( [fileName isEqualToString:[file fileName]] )
		{
			[self selectFile:file];
			break;
		}
	}
	
	// 3. Read in & setup navigation stack
	NSArray *controllerStack = [defaults objectForKey:DEFS_CURRENT_CONTROLLER_STACK];
	for( NSString *controllerId in controllerStack )
	{
		UIViewController *controller = [self controllerForId:controllerId];
		if( controller )
			[self pushViewController:controller animated:NO];
	}
	[self updateBadgeValueUsingItem:[self topViewController].navigationItem push:YES];

	// 4. Scroll the table view to the last position, and if we were watching item details,
	// show those as well.
	NSDictionary *indexPathDictionary = [defaults objectForKey:DEFS_INDEX_PATH];
	if( [indexPathDictionary isKindOfClass:[NSDictionary class]] )
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathWithDictionary:indexPathDictionary];
		if( [self topViewController] == fancyDetailsController )
		{
			if( [itemController itemExistsAtIndexPath:indexPath] )
			{
				[[itemController tableView] selectRowAtIndexPath:indexPath
														animated:NO
												  scrollPosition:UITableViewScrollPositionMiddle];
				[self selectDetailsForRow:[itemController indexForObjectAtIndexPath:indexPath]];
			}
		}
		else if([[self topViewController] isKindOfClass:[OzyTableViewController class]] &&
				[(OzyTableViewController *)[self topViewController] itemExistsAtIndexPath:indexPath])
		{
			[[(OzyTableViewController *)[self topViewController] tableView] scrollToRowAtIndexPath:indexPath
																				  atScrollPosition:UITableViewScrollPositionTop
																						  animated:NO];
		}
	}	
}

- (void) setSize:(NSInteger)size
{
	itemController.size = size;
	fancyDetailsController.size = size;
}

static CSVDataViewController *sharedInstance = nil;

+ (CSVDataViewController *) sharedInstance
{
	return sharedInstance;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	sharedInstance = self;
	columnNamesForFileName = [[NSMutableDictionary alloc] init];
	indexPathForFileName = [[NSMutableDictionary alloc] init];
	searchStringForFileName = [[NSMutableDictionary alloc] init];
	columnIndexes = [[NSMutableArray alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(tableViewContentChanged:)
												 name:OzyContentChangedInTableView
											   object:nil];	
	return self;
}

- (void) dealloc
{
	[detailsController release];
	[itemController release];
	[editController release];
	[fileController release];
	[fancyDetailsController release];
	[parseErrorController release];
	[currentFile release];
	[columnNamesForFileName release];
	[indexPathForFileName release];
	[searchStringForFileName release];
	[columnIndexes release];
	if( rawColumnIndexes )
		free(rawColumnIndexes);
	[super dealloc];
}

- (void) resetColumnNames
{
	[columnNamesForFileName removeObjectForKey:[currentFile fileName]];
	[self updateColumnNames];
	itemsNeedResorting = YES;
}

- (IBAction) resetColumnNames:(id)sender
{
	[self resetColumnNames];
}

- (void) tableViewContentChanged:(NSNotification *)n
{
	if( [n object] == editController )
	{
		[columnNamesForFileName setObject:[editController objects] forKey:[currentFile fileName]];
		[self updateColumnIndexes];
		itemsNeedResorting = YES;
	}
	else if( [n object] == fileController )
	{
		CSVFileParser *removedFile = [[n userInfo] objectForKey:OzyRemovedTableViewObject];
		if( removedFile )
		{
			[[NSFileManager defaultManager] removeItemAtPath:[removedFile filePath] error:NULL];
			[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
		}
	}
}

+ (NSString *) parseErrorStringForFile:(CSVFileParser *)file
{
	NSMutableString *s = [NSMutableString string];
	
	// What type of problem?
	if( file.problematicRow && ![file.problematicRow isEqualToString:@""] )
	{
		[s appendFormat:@"Different number of objects in different rows. Potentially first problematic row:\n\n%@\n\n", file.problematicRow];
		if( [CSVPreferencesController keepQuotes] && [file.problematicRow hasSubstring:@"\""])
			[s appendString:@"Try switching off the \"Keep Quotes\"-setting."];
	}
	else if( [file.rawString length] == 0 )
	{
		[s appendString:@"Couldn't read the file using the selected encoding."];
	}
	else
	{
		[s appendFormat:@"Found %d items in %d columns, using delimiter '%C'; check \"Data\" preferences.\n\n",
		 [[file itemsWithResetShortdescriptions:NO] count],
		 [[file availableColumnNames] count],
		 file.usedDelimiter];
		[s appendFormat:@"File read when using the selected encoding:\n\n%@", file.rawString];
	}
	
	return s;
}

- (IBAction) toggleShowingRawString:(id)sender
{
	if( showingRawString )
	{
		[[parseErrorController textView] setText:[CSVDataViewController parseErrorStringForFile:currentFile]];
	}
	else
	{
		[[parseErrorController textView] setText:[NSString stringWithFormat:@"File read when using the selected encoding:\n\n%@", currentFile.rawString]];
	}
	showingRawString = !showingRawString;
}

- (void) delayedPushItemController:(CSVFileParser *)selectedFile
{
	[[CSV_TouchAppDelegate sharedInstance] slowActivityCompleted];

	if( currentFile != selectedFile )
	{
		[self selectFile:selectedFile];
		[[itemController tableView] deselectRowAtIndexPath:[[itemController tableView] indexPathForSelectedRow]
												 animated:NO];
		[itemController dataLoaded];
	}
	
	// Check if there seems to be a problem with the file preventing us from reading it
	if( [[currentFile itemsWithResetShortdescriptions:NO] count] < 2 ||
		[[currentFile availableColumnNames] count] == 0 ||
	   ([[currentFile availableColumnNames] count] == 1 && [CSVPreferencesController showDebugInfo]) )
	{
		showingRawString = NO;
		[[parseErrorController textView] setText:[CSVDataViewController parseErrorStringForFile:currentFile]];
		[self pushViewController:parseErrorController animated:YES];
	}
	else
	{
		// We could read the file and will display it, but we should also check if we have dropped any other problems
		if( [CSVPreferencesController showDebugInfo] )
		{
			if( currentFile.droppedRows > 0 )
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dropped Rows!"
																message:[NSString stringWithFormat:@"%d rows dropped due to problems reading them. Last dropped row:\n%@",
																		 currentFile.droppedRows, currentFile.problematicRow]
															   delegate:[[UIApplication sharedApplication] delegate]
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
			}
			else if([[currentFile availableColumnNames] count] != 
					[[NSSet setWithArray:[currentFile availableColumnNames]] count] )
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Identical Column Titles!"
																message:@"Some of the columns have the same title; this makes some functionality involving columns behave weird"
															   delegate:[[UIApplication sharedApplication] delegate]
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
			}
		}
		[self pushViewController:itemController animated:YES];
	}
}

- (IBAction) toggleDetailsView:(id)sender
{
	if( [self topViewController] == detailsController )
	{
		[self popViewControllerAnimated:NO];
		[self pushViewController:fancyDetailsController animated:NO];
	}
	else
	{
		[self popViewControllerAnimated:NO];
		[self pushViewController:detailsController animated:NO];
	}	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( tableView == [itemController tableView] )
	{
		[self selectDetailsForRow:[itemController indexForObjectAtIndexPath:indexPath]];
		[self pushViewController:fancyDetailsController animated:YES];
	}
	else if( tableView == [fileController tableView] )
	{
		if( refreshingFilesInProgress )
		{
			[[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:[(CSVFileParser *)[[fileController objects] objectAtIndex:indexPath.row] URL]];
		}
		else
		{
			CSVFileParser *selectedFile = [[fileController objects] objectAtIndex:indexPath.row];
			if( [selectedFile stringLength] > 75000 && selectedFile != currentFile && !selectedFile.hasBeenSorted )
			{
				[[CSV_TouchAppDelegate sharedInstance] slowActivityStartedInViewController:self];
			}
			[self performSelector:@selector(delayedPushItemController:)
					   withObject:selectedFile
					   afterDelay:0];
		}
	}
}

- (IBAction) edit:(id)sender
{
	if( [CSVPreferencesController useBlackTheme] )
	{
		searchBar.barStyle = UIBarStyleBlackOpaque;
		editNavigationBar.barStyle = UIBarStyleBlackOpaque;
	}
	
	[editController setTitle:[currentFile tableViewDescription]];
	[self presentModalViewController:editController animated:YES];
}

- (IBAction) editDone:(id)sender
{
	[searchBar endEditing:YES];
	if( itemsNeedResorting || itemsNeedFiltering )
	{
		[self refreshObjectsWithResorting:itemsNeedResorting];
		itemsNeedResorting = itemsNeedFiltering = NO;
	}
	[self updateBadgeValueUsingItem:itemController.navigationItem push:YES];
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar 
		shouldPopItem:(UINavigationItem *)item
{
	[self updateBadgeValueUsingItem:item push:NO];
	return [(<UINavigationBarDelegate>)super navigationBar:navigationBar shouldPopItem:item];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar 
		shouldPushItem:(UINavigationItem *)item
{
	[self updateBadgeValueUsingItem:item push:YES];
	return YES;
}	

- (void) setFiles:(NSArray *) newFiles
{
	NSMutableArray *files = [NSMutableArray arrayWithArray:newFiles];
	[files sortUsingSelector:@selector(compareFileName:)];
	[fileController setObjects:files];
	[fileController dataLoaded];
	if( [self topViewController] == fileController )
		[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
}

- (void) markFilesAsDirty
{
	for( CSVFileParser *fileParser in [fileController objects] )
		fileParser.hasBeenParsed = NO;
	[self updateColumnNames];
	[self refreshObjectsWithResorting:YES];
	[self updateBadgeValueUsingItem:[self topViewController].navigationItem push:YES];
}

- (void) resortObjects
{
	[[itemController objects] sortUsingSelector:@selector(compareShort:)];
	[itemController refreshIndexes];
	[itemController dataLoaded];
}

- (void) newFileDownloaded:(CSVFileParser *)newFile
{
	for( NSUInteger i = 0 ; i < [[fileController objects] count] ; i++ )
	{
		CSVFileParser *oldFile = [[fileController objects] objectAtIndex:i];
		if( [[newFile fileName] isEqualToString:[oldFile fileName]] )
		{
			[[fileController objects] removeObjectAtIndex:i];
			break;
		}
	}
	[[fileController objects] addObject:newFile];
	[[fileController objects] sortUsingSelector:@selector(compareFileName:)];
	[fileController dataLoaded];
	if( [self topViewController] == fileController )
		[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
}
			
- (UIBarButtonItem *) refreshFilesItem
{
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
														  target:self 
														  action:@selector(toggleRefreshFiles:)] autorelease];
}

- (UIBarButtonItem *) stopRefreshingFilesItem
{
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
														  target:self 
														  action:@selector(toggleRefreshFiles:)] autorelease];
}

- (IBAction) toggleRefreshFiles:(id)sender
{
	refreshingFilesInProgress = !refreshingFilesInProgress;
	if( refreshingFilesInProgress )
	{
		fileController.removeDisclosure = YES;
		[fileController.navigationItem setRightBarButtonItem:[self stopRefreshingFilesItem] animated:YES];
	}
	else
	{
		fileController.removeDisclosure = NO;
		[fileController.navigationItem setRightBarButtonItem:[self refreshFilesItem] animated:YES];
	}
	[fileController dataLoaded];
}

- (void)searchBar:(UISearchBar *)modifiedSearchBar textDidChange:(NSString *)searchText
{
	if( searchBar == modifiedSearchBar )
		itemsNeedFiltering = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self performSelector:@selector(editDone:) withObject:self afterDelay:0];
}

@end

