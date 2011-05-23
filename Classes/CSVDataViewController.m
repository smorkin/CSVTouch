//
//  CSVDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVDataViewController.h"
#import "OzyTableViewController.h"
#import "OzyWebViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "CSVPreferencesController.h"
#import "CSVFileParser.h"
#import "CSVRow.h"
#import "OzyTextViewController.h"
#import "OzymandiasAdditions.h"

#define FILES_ID @"filesID"
#define OBJECTS_ID @"objectsID"
#define DETAILS_ID @"detailsID"

#define MAX_ITEMS_IN_LITE_VERSION 150

@interface NSString (FancyDetailsComparison)
- (NSComparisonResult) compareFancyDetails:(NSString *)s;
@end

@implementation NSString (FancyDetailsComparison)
- (NSComparisonResult) compareFancyDetails:(NSString *)s
{
	return [self compare:s options:sortingMask];
}
@end


#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@interface CSVDataViewController (AdBannerViewDelegate) <ADBannerViewDelegate>
@end
#endif


@implementation CSVDataViewController

@synthesize itemsToolbar;
@synthesize filesToolbar;
@synthesize searchBar;
@synthesize leaveAppURL;
@synthesize showDeletedColumns = _showDeletedColumns;
@synthesize contentView = _contentView;
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@synthesize bannerView = _bannerView;
@synthesize bannerIsVisible = _bannerIsVisible;
#endif

- (CSVFileParser *) currentFile
{
	return currentFile;
}

- (NSArray *) files
{
	return [fileController objects];
}

- (int) numberOfFiles
{
	return [[fileController objects] count];
}

- (BOOL) fileExistsWithURL:(NSString *)URL
{
	for( CSVFileParser *fp in [fileController objects] )
	{
		if( [fp.URL isEqualToString:URL] )
			return YES;
	}
	return NO;
}

- (void) refreshObjectsWithResorting:(BOOL)needsResorting
{
	NSMutableArray *allObjects = [currentFile itemsWithResetShortdescriptions:needsResorting];
	NSMutableArray *filteredObjects = [NSMutableArray array];
	NSMutableArray *workObjects;
	NSString *searchString = [searchBar.text lowercaseString];
	
	// We should always resort all objects, no matter which are actually shown
	if( needsResorting &&
	   ([CSVPreferencesController maxNumberOfItemsToSort] == 0 ||
		[allObjects count] <= [CSVPreferencesController maxNumberOfItemsToSort]) )
	{
		[allObjects sortUsingSelector:[CSVRow compareSelector]];
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
				wordNr < wordCount && [objectDescription hasSubstring:[words objectAtIndex:wordNr]]; 
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
	
	if( [CSVPreferencesController restrictedDataVersionRunning] && [workObjects count] > MAX_ITEMS_IN_LITE_VERSION )
		[workObjects removeObjectsInRange:NSMakeRange(MAX_ITEMS_IN_LITE_VERSION, [workObjects count] - MAX_ITEMS_IN_LITE_VERSION)];
	
	[itemController setObjects:workObjects];
	[itemController dataLoaded];
}

- (void) setHiddenColumns:(NSIndexSet *)hidden forFile:(NSString *)fileName
{
	[_preDefinedHiddenColumns setObject:hidden forKey:fileName];
}

- (NSArray *) importantColumnIndexes
{
	return importantColumnIndexes;
}

- (int *) rawColumnIndexes
{
	return rawColumnIndexes;
}

- (void) updateColumnIndexes
{
	NSArray *availableColumns = [currentFile availableColumnNames];
	[importantColumnIndexes removeAllObjects];
	if( rawColumnIndexes )
		free(rawColumnIndexes);
	for( NSString *usedColumn in [editController objects] )
	{
		for( NSUInteger i = 0 ; i < [availableColumns count] ; i++ )
			if( [usedColumn isEqualToString:[availableColumns objectAtIndex:i]] )
				[importantColumnIndexes addObject:[NSNumber numberWithInt:i]];
	}
	rawColumnIndexes = malloc(sizeof(int) * [importantColumnIndexes count]);
	for( int i = 0 ; i < [importantColumnIndexes count] ; i++ )
		rawColumnIndexes[i] = [[importantColumnIndexes objectAtIndex:i] intValue];
}

- (void) updateColumnNames
{
	NSArray *names = [columnNamesForFileName objectForKey:[currentFile fileName]];
	if( !names )
	{
		NSArray *availableNames = [currentFile availableColumnNames];
		// Do we have any predefined hidden columns?
		NSIndexSet *hidden = [_preDefinedHiddenColumns objectForKey:[currentFile fileName]];
		if(hidden &&
		   [hidden isKindOfClass:[NSIndexSet class]] &&
		   [hidden count] > 0)
		{
			NSMutableArray *tmpNames = [NSMutableArray array];
			for( NSUInteger index = 0 ; index < [availableNames count] ; index++)
			{
				if( ![hidden containsIndex:index] )
					[tmpNames addObject:[availableNames objectAtIndex:index]];
			}
			names = tmpNames;
		}
		else
		{
			names = [currentFile availableColumnNames];
		}
		[_preDefinedHiddenColumns removeObjectForKey:[currentFile fileName]];
		[columnNamesForFileName setObject:names forKey:[currentFile fileName]];
	}
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

- (void) updateFileModificationDateButton
{
	NSString *date;
	NSString *time;
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];

	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	date = [dateFormatter stringFromDate:currentFile.downloadDate];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	time = [dateFormatter stringFromDate:currentFile.downloadDate];
	
	[(UILabel *)modificationDateButton.customView setText:[NSString stringWithFormat:@"%@\n%@",
								   date, time]]; 
}

- (BOOL) selectFile:(CSVFileParser *)file
{		
	// Store current position of itemController and search string
	[self cacheCurrentFileData];
	
	[currentFile release];
	currentFile = [file retain];
	[currentFile parseIfNecessary];
	
	if( !currentFile.rawString )
	{
		return FALSE;
	}
	NSString *cachedSearchString = [searchStringForFileName objectForKey:[currentFile fileName]];
	if( cachedSearchString )
		searchBar.text = cachedSearchString;
	else
		searchBar.text = @"";
	[self updateColumnNames];
	[itemController setTitle:[currentFile defaultTableViewDescription]];
	[self updateFileModificationDateButton];
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
	return TRUE;
}

- (UIViewController *) currentDetailsController
{
	switch(selectedDetailsView)
	{
		case 0:
			return fancyDetailsController;
		case 1:
			return htmlDetailsController;
		case 2:
		default:
			return detailsController;
	}
}

- (void) updateBadgeValueUsingItem:(UINavigationItem *)item push:(BOOL)push
{
	NSUInteger count = 0;
	
	// Details controller will be visible
	if(push &
	   (item == detailsController.navigationItem ||
		item == fancyDetailsController.navigationItem ||
		item == htmlDetailsController.navigationItem))
	{
		NSIndexPath *selectedRow = [[itemController tableView] indexPathForSelectedRow];
		if( selectedRow &&
		   [itemController indexForObjectAtIndexPath:selectedRow] >= 0 )
		{
			count = [itemController indexForObjectAtIndexPath:selectedRow] + 1;
		}
		else
		{
			count = 0;
		}
		NSString *s = [NSString stringWithFormat:@"%d/%d", count, [[itemController objects] count]];
		detailsController.title = s;
		fancyDetailsController.title = s;
		htmlDetailsController.title = s;
	}
	// Item controller will be visible
	else if((push && item == itemController.navigationItem) || 
			(!push && item == detailsController.navigationItem) ||
			(!push && item == fancyDetailsController.navigationItem) ||
			(!push && item == htmlDetailsController.navigationItem))
	{
		NSString *addString = @"";
		count = [[itemController objects] count];
		if( count != [[currentFile itemsWithResetShortdescriptions:NO] count] )
			addString = [NSString stringWithFormat:@"/%d", [[currentFile itemsWithResetShortdescriptions:NO] count]];
		itemsCountButton.title = [NSString stringWithFormat:@"%d%@", count, addString];
	}
	// File controller will be visible (or parseErrorController involved, in which case always use Files data)
	else if((!push && item == itemController.navigationItem) ||
			(push && item == fileController.navigationItem) ||
			(item == parseErrorController.navigationItem))
	{
		count = [[fileController objects] count];
		filesCountButton.title = [NSString stringWithFormat:@"%d", count];
	}
}

- (void) updateSimpleViewWithItem:(CSVRow *)item
{
	if( item )
		[[detailsController textView] setText:[item longDescriptionWithHiddenValues:self.showDeletedColumns]];
	else
		[[detailsController textView] setText:@"No data found!"];
}

- (void) updateEnhancedViewWithItem:(CSVRow *)item
{
	NSMutableArray *items = [item longDescriptionInArrayWithHiddenValues:self.showDeletedColumns];
	fancyDetailsController.objects = items;
	fancyDetailsController.removeDisclosure = YES;
	if( [[currentFile availableColumnNames] count] > [importantColumnIndexes count] )
	{
		NSArray *sectionStarts = [NSArray arrayWithObjects:
								  [NSNumber numberWithInt:0], 
								  [NSNumber numberWithInt:[importantColumnIndexes count]],
								  nil];
		[fancyDetailsController setSectionStarts:sectionStarts];
	}
	else
	{
		[fancyDetailsController setSectionStarts:nil];
	}
	[fancyDetailsController dataLoaded];
}

- (void) updateHtmlViewWithItem:(CSVRow *)item
{
	[htmlDetailsController.webView stopLoading];
	
	BOOL useTable = [CSVPreferencesController alignHtml];
	NSError *error;
	NSString *cssString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"seaglass" ofType:@"css"]
												usedEncoding:nil
													   error:&error];
	
	NSMutableString *s = [NSMutableString string];
	[s appendString:@"<html><head><title>Details</title>"];
	[s appendString:@"<STYLE type=\"text/css\">"];
	[s appendString:cssString];
	[s appendString:@"</STYLE>"];
	
	if( [CSV_TouchAppDelegate iPadMode] )
	{
		if(htmlDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
		   htmlDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
		{
			[s replaceOccurrencesOfString:@"normal 36px verdana" 
							   withString:@"normal 18px verdana" 
								  options:0
									range:NSMakeRange(0, [s length])];		
		}
		else 
		{
			[s replaceOccurrencesOfString:@"normal 36px verdana" 
							   withString:@"normal 24px verdana" 
								  options:0
									range:NSMakeRange(0, [s length])];					
		}
	}
	else if(htmlDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
	   htmlDetailsController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
	{
		[s replaceOccurrencesOfString:@"normal 36px verdana" 
						   withString:@"normal 24px verdana" 
							  options:0
								range:NSMakeRange(0, [s length])];		
	}
	[s appendString:@"</head><body>"];
	if( useTable )
		[s appendString:@"<table width=\"100%\">"];
	else
		[s appendFormat:@"<p><font size=\"+5\">"];
	NSMutableString *data = [NSMutableString string];
	NSArray *columnsAndValues = [item columnsAndValues];
	NSInteger row = 1;
	for( NSDictionary *d in columnsAndValues )
	{
		// Are we done already?
		if(row > [[self importantColumnIndexes] count] &&
		   !self.showDeletedColumns)
			break;
		
		if( useTable )
		{
			if(row != 1 && // In case someone has a file where no column is important...
			   row-1 == [[self importantColumnIndexes] count] &&
			   [[self importantColumnIndexes] count] != [columnsAndValues count] )
			{
				[data appendString:@"<tr class=\"rowstep\"><th><b>-</b><td>"]; 
				[data appendString:@"<tr class=\"rowstep\"><th><b>-</b><td>"]; 
			}
			
			[data appendFormat:@"<tr%@><th valign=\"top\"><b>%@</b>", 
			 ((row % 2) == 1 ? @" class=\"odd\"" : @""),
			 [d objectForKey:COLUMN_KEY]];
			if( [[d objectForKey:VALUE_KEY] containsImageURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<td><img src=\"%@\">", [d objectForKey:VALUE_KEY]];
			else if( [[d objectForKey:VALUE_KEY] containsURL] )
				[data appendFormat:@"<td><a href=\"%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
			else if( [[d objectForKey:VALUE_KEY] containsMailAddress] )
				[data appendFormat:@"<td><a href=\"mailto:%@\">%@</a>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
			else
				[data appendFormat:@"<td>%@", [d objectForKey:VALUE_KEY]];
		}
		else
		{
			[data appendFormat:@"<b>%@</b>: ", [d objectForKey:COLUMN_KEY]];
			if( [[d objectForKey:VALUE_KEY] containsImageURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<br><img src=\"%@\"><br>", [d objectForKey:VALUE_KEY]];
			else if( [[d objectForKey:VALUE_KEY] containsURL] )
				[data appendFormat:@"<a href=\"%@\">%@</a><br>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
			else if( [[d objectForKey:VALUE_KEY] containsMailAddress] )
				[data appendFormat:@"<a href=\"mailto:%@\">%@</a><br>", [d objectForKey:VALUE_KEY], [d objectForKey:VALUE_KEY]];
			else
				[data appendFormat:@"%@<br>", [d objectForKey:VALUE_KEY]];
		}
		row++;
	}
	[data replaceOccurrencesOfString:@"\n" 
						  withString:@"<br>" 
							 options:0
							   range:NSMakeRange(0, [data length])];
	[s appendString:data];
	if( useTable )
		[s appendFormat:@"</table>"];
	else
		[s appendFormat:@"</p>"];
	[s appendFormat:@"</body></html>"];
	[htmlDetailsController.webView loadHTMLString:s baseURL:nil];
}

- (void) selectDetailsForRow:(NSUInteger)row
{	
	if( [[itemController objects] count] > row )
		_latestShownItem = [[itemController objects] objectAtIndex:row];
	else
		_latestShownItem = nil;
	
	[self updateSimpleViewWithItem:_latestShownItem];
	[self updateEnhancedViewWithItem:_latestShownItem];
	[self updateHtmlViewWithItem:_latestShownItem];
	[self updateBadgeValueUsingItem:[[self currentDetailsController] navigationItem] push:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if( [alertView isEqual:leaveAppView] )
	{
		if( buttonIndex == 1 && leaveAppURL )
			[[UIApplication sharedApplication] openURL:leaveAppURL];
		[leaveAppView release];
		leaveAppView = nil;
		self.leaveAppURL = nil;
	}
}	

- (void) delayedHtmlClick:(NSURL *)URL
{
	if( [CSVPreferencesController confirmLink] )
	{
		self.leaveAppURL = URL;
		leaveAppView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Leave %@", 
														   ([CSVPreferencesController restrictedDataVersionRunning] ? @"CSV Lite" : @"CSV Touch")]
												  message:[NSString stringWithFormat:@"Continue opening %@?", [self.leaveAppURL absoluteString]]
												 delegate:self
										cancelButtonTitle:@"Cancel"
										otherButtonTitles:@"Leave", nil];
		[leaveAppView show];
	}
	else
	{
		[[UIApplication sharedApplication] openURL:URL];
	}
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	if( navigationType == UIWebViewNavigationTypeLinkClicked )
	{
		[self performSelector:@selector(delayedHtmlClick:)
				   withObject:[request URL]
				   afterDelay:0];
		return NO;
	}
	return YES;
}

// UIWebViewDelegate protocol
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if( [CSVPreferencesController showDebugInfo] )
	{
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Load error!"
														 message:[NSString stringWithFormat:@"Error when loading view. Description: %@\nCode: %d",
																  [error localizedDescription], [error code]]
														delegate:[[UIApplication sharedApplication] delegate]
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
		[alert show];
		
	}
}

- (void) validateItemSizeButtons
{
	OzyTableViewSize s = [CSVPreferencesController itemsTableViewSize];
	shrinkItemsButton.enabled = (s == OZY_MINI ? NO : YES);
	enlargeItemsButton.enabled = (s == OZY_NORMAL? NO : YES);
}

- (void) updateShowHideDeletedColumnsButtons
{
	NSString *title = (self.showDeletedColumns ? @"Hide" : @"Show");
	[[[detailsViewToolbar items] objectAtIndex:0] setTitle:title];
	[[[fancyDetailsViewToolbar items] objectAtIndex:0] setTitle:title];
	[[[htmlDetailsViewToolbar items] objectAtIndex:0] setTitle:title];
}

- (NSString *) idForController:(UIViewController *)controller
{
	if( controller == fileController )
		return FILES_ID;
	else if( controller == itemController )
		return OBJECTS_ID;
	else if( controller == fancyDetailsController ||
			controller == detailsController ||
			controller == htmlDetailsController)
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
	{
		if( selectedDetailsView == 0 )
			return fancyDetailsController;
		else if( selectedDetailsView == 1 )
			return htmlDetailsController;
		else
			return detailsController;
	}
	else
		return nil;	
}

#define DEFS_COLUMN_NAMES @"defaultColumnNames"
#define DEFS_CURRENT_FILE @"currentFile"
#define DEFS_CURRENT_CONTROLLER_STACK @"currentControllerStack"
#define DEFS_INDEX_PATH @"indexPath"
#define DEFS_ITEM_POSITIONS_FOR_FILES @"itemPositionsForFiles"
#define DEFS_SEARCH_STRINGS_FOR_FILES @"searchStringsForFiles"
#define DEFS_SELECTED_DETAILS_VIEW @"selectedDetailsView"
#define DEFS_PREDEFINED_HIDDEN_COLUMNS @"predefinedHiddenColumns"


- (void) applicationWillTerminate
{
	[self cacheCurrentFileData];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( columnNamesForFileName )
	{
		[defaults setObject:columnNamesForFileName forKey:DEFS_COLUMN_NAMES];
	}
	
	if( indexPathForFileName )
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
	
	if( [_preDefinedHiddenColumns count] > 0 )
	{
		[defaults setObject:_preDefinedHiddenColumns forKey:DEFS_PREDEFINED_HIDDEN_COLUMNS];
	}
	else
	{
		[defaults removeObjectForKey:DEFS_PREDEFINED_HIDDEN_COLUMNS];
	}
	
	if( [self topViewController] != fileController )
		[defaults setObject:[currentFile fileName] forKey:DEFS_CURRENT_FILE];
	else
		[defaults removeObjectForKey:DEFS_CURRENT_FILE];
	
	NSMutableArray *controllerStack = [NSMutableArray array];
	for( UIViewController *controller in [self viewControllers] )
		[controllerStack addObject:[self idForController:controller]];
	[defaults setObject:controllerStack forKey:DEFS_CURRENT_CONTROLLER_STACK];
	
	if( [self topViewController] == detailsController ||
	   [self topViewController] == fancyDetailsController ||
	   [self topViewController] == htmlDetailsController )
	{
		[defaults setObject:[[[itemController tableView] indexPathForSelectedRow] dictionaryRepresentation]
					 forKey:DEFS_INDEX_PATH];
	}
	else if( [self topViewController] == itemController )
	{
		NSArray *a = [[itemController tableView] indexPathsForVisibleRows];
		if( [a count] > 0 )
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
	
	[defaults setInteger:selectedDetailsView forKey:DEFS_SELECTED_DETAILS_VIEW];
	
	[defaults synchronize];
}

- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL)emergencyMode
{	
	// If someone wants to have this button, it is likely they don't want to see the columns as default
	if( [CSVPreferencesController showDetailsToolbar] )
	{
		self.showDeletedColumns = FALSE;
	}
	else
	{
		for( UIView *subview in [[fancyDetailsController view] subviews] )
		{
			if( [subview isKindOfClass:[UIToolbar class]] )
			{
				CGFloat height = [subview frame].size.height;
				CGRect frame = [fancyDetailsController.tableView frame];
				frame.size.height += height;
				[subview removeFromSuperview];
				[fancyDetailsController.tableView setFrame:frame];
				break;
			}
		}
		for( UIView *subview in [[detailsController view] subviews] )
		{
			if( [subview isKindOfClass:[UIToolbar class]] )
			{
				CGFloat height = [subview frame].size.height;
				CGRect frame = [detailsController.textView frame];
				frame.size.height += height;
				[subview removeFromSuperview];
				[detailsController.textView setFrame:frame];
				break;
			}
		}
		for( UIView *subview in [[htmlDetailsController view] subviews] )
		{
			if( [subview isKindOfClass:[UIToolbar class]] )
			{
				CGFloat height = [subview frame].size.height;
				CGRect frame = [htmlDetailsController.webView frame];
				frame.size.height += height;
				[subview removeFromSuperview];
				[htmlDetailsController.webView setFrame:frame];
				break;
			}
		}
		self.showDeletedColumns = TRUE;
	}
	[self updateShowHideDeletedColumnsButtons];
	
	// Setup stuff for controllers which can't be configured using InterfaceBuilder
	[[editController tableView] setEditing:YES animated:NO];
	editController.editable = YES;
	editController.reorderable = YES;
	editController.size = OZY_NORMAL;
	[editController setSectionTitles:[NSArray arrayWithObject:@"Select & Arrange Columns"]];
	fileController.editable = YES;
	fileController.size = OZY_NORMAL;
	itemController.editable = NO;
	itemController.size = [CSVPreferencesController itemsTableViewSize];
	itemController.useIndexes = [CSVPreferencesController useGroupingForItems];
	itemController.groupNumbers = [CSVPreferencesController groupNumbers];
	itemController.useFixedWidth = [CSVPreferencesController useFixedWidth];
	fancyDetailsController.size = [CSVPreferencesController detailsTableViewSize];
	detailsController.viewDelegate = self;
	fancyDetailsController.viewDelegate = self;
	htmlDetailsController.viewDelegate = self;
	
	// Setup modificationdate/time label
	CGRect frame = CGRectMake(0, 0, 72, 44);
	UILabel *l = [[[UILabel alloc] initWithFrame:frame] autorelease];
	l.font = [UIFont fontWithName:l.font.fontName size:10];
	l.backgroundColor = [UIColor clearColor];
	if([CSV_TouchAppDelegate iPadMode] &&
	   ![CSVPreferencesController useBlackTheme])
		l.textColor = [UIColor darkGrayColor];
	else
		l.textColor = [UIColor whiteColor];
	l.lineBreakMode = UILineBreakModeWordWrap;
	l.textAlignment = UITextAlignmentCenter;
	l.numberOfLines = 2;
	modificationDateButton.customView = l;
	
	// Disable phone links, if desired
	if( [CSVPreferencesController enablePhoneLinks] == FALSE )
		[htmlDetailsController.webView setDataDetectorTypes:UIDataDetectorTypeLink];
	
	// Autocorrection of searching should be off
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	itemController.tableView.tableHeaderView = searchBar;
	
	// Push the fileController to the root of the navigation;
	// we must do this in case we have no saved navigationstack
	[self pushViewController:fileController animated:NO];
	[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];

	// Fix simple mode (note that this must be done AFTER pushing the file controller
	// onto the navigation stack, to correctly get to the download new file-button)
	if( [CSVPreferencesController simpleMode] )
	{
		NSMutableArray *keptItems = [NSMutableArray array];
		
		for( UIBarButtonItem *item in [itemsToolbar items] )
		{
			if( [item action] != @selector(editColumns:))
				[keptItems addObject:item];
		}
		[itemsToolbar setItems:keptItems animated:NO];
		
		[keptItems removeAllObjects];
		for( UIBarButtonItem *item in [filesToolbar items] )
		{
			if( [CSVPreferencesController lastUsedListURL] )
			{
				if([item action] == @selector(loadFileList))
					[keptItems addObject:item];
			}
			else
			{
				if([item action] != @selector(toggleEditFiles) &&
				   [item action] != @selector(toggleShowFileInfo:))
					[keptItems addObject:item];				
			}
		}
		[filesToolbar setItems:keptItems animated:NO];
		
		self.navigationBar.topItem.rightBarButtonItem = nil;
		fileController.editable = NO;
	}
	
	// Read last state to be able to get back to where we were before quitting last time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// 0. Extra settings
	selectedDetailsView = [defaults integerForKey:DEFS_SELECTED_DETAILS_VIEW];
	
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
	
	// Also read in any predefined hidden columns
	NSDictionary *predefinedHiddenColumns = [defaults objectForKey:DEFS_PREDEFINED_HIDDEN_COLUMNS];
	if( predefinedHiddenColumns && [predefinedHiddenColumns isKindOfClass:[NSDictionary class]] )
	{
		[_preDefinedHiddenColumns release];
		_preDefinedHiddenColumns = [[NSMutableDictionary alloc] initWithDictionary:predefinedHiddenColumns];
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
		if( controller && controller != fileController )
		{
			[self pushViewController:controller animated:NO];
		}
	}
	[self updateBadgeValueUsingItem:[self topViewController].navigationItem push:YES];
	
	// 4. Scroll the table view to the last position, and if we were watching item details,
	// show those as well.
	NSDictionary *indexPathDictionary = [defaults objectForKey:DEFS_INDEX_PATH];
	if( [indexPathDictionary isKindOfClass:[NSDictionary class]] )
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathWithDictionary:indexPathDictionary];
		if([self topViewController] == fancyDetailsController ||
		   [self topViewController] == htmlDetailsController ||
		   [self topViewController] == detailsController)
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
	
	// Enable/Disable item size buttons
	[self validateItemSizeButtons];
}

- (void) modifyItemsTableViewSize:(BOOL)increase
{
	if( [CSVPreferencesController modifyItemsTableViewSize:increase] )
	{
		NSArray *a = [[itemController tableView] indexPathsForVisibleRows];
		NSIndexPath *oldIndexPath = nil;	
		if( [a count] > 0 )
			oldIndexPath = [a objectAtIndex:0];
		itemController.size = [CSVPreferencesController itemsTableViewSize];
		if( oldIndexPath )
			[itemController.tableView scrollToRowAtIndexPath:oldIndexPath
											atScrollPosition:UITableViewScrollPositionTop
													animated:NO];
	}
}

- (IBAction) increaseTableViewSize
{
	[self modifyItemsTableViewSize:YES];
	[self validateItemSizeButtons];
}

- (IBAction) decreaseTableViewSize
{
	[self modifyItemsTableViewSize:NO];
	[self validateItemSizeButtons];
}

- (IBAction) toggleShowHideDeletedColumns
{
	self.showDeletedColumns = !self.showDeletedColumns;
	[self updateShowHideDeletedColumnsButtons];
	[self updateSimpleViewWithItem:_latestShownItem];
	[self updateEnhancedViewWithItem:_latestShownItem];
	[self updateHtmlViewWithItem:_latestShownItem];
}

static CSVDataViewController *sharedInstance = nil;

+ (CSVDataViewController *) sharedInstance
{
	return sharedInstance;
}

- (void) setupBannerView
{
	// Ads
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	NSString *contentSize;
	if( UIInterfaceOrientationIsPortrait(self.interfaceOrientation) )
	{
		if ([CSVPreferencesController canUseAbstractBannerNames] )
			contentSize = ADBannerContentSizeIdentifierPortrait;
		else
			contentSize = ADBannerContentSizeIdentifier320x50;
	}
	else
	{
		if ([CSVPreferencesController canUseAbstractBannerNames] )
			contentSize = ADBannerContentSizeIdentifierLandscape;
		else
			contentSize = ADBannerContentSizeIdentifier480x32;
	}
	
	// First, fix views
	// We need the view to contain our contentview which contains all old views...
	self.contentView = [[UIView alloc] initWithFrame:self.view.frame];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	// Now move over old subviews to contentview
	NSArray *oldViews = [self.view subviews];
	for( UIView *view in oldViews )
		[self.contentView addSubview:view];
	// And finally, fix hierarchy
	[self.view addSubview:self.contentView];
	
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0, CGRectGetMaxY(self.view.bounds));
	
	ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    bannerView.delegate = self;
    // Set the autoresizing mask so that the banner is pinned to the bottom
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
	
	// On iOS 4.2, default is both portrait and landscape
	if (![CSVPreferencesController canUseAbstractBannerNames] )
		bannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects: ADBannerContentSizeIdentifier320x50,
														  ADBannerContentSizeIdentifier480x32,
														  nil];
	
	[self.view addSubview:bannerView];
    self.bannerView = bannerView;
    [bannerView release];	
	
#endif	
}


- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	sharedInstance = self;
	columnNamesForFileName = [[NSMutableDictionary alloc] init];
	indexPathForFileName = [[NSMutableDictionary alloc] init];
	searchStringForFileName = [[NSMutableDictionary alloc] init];
	importantColumnIndexes = [[NSMutableArray alloc] init];
	_preDefinedHiddenColumns = [[NSMutableDictionary alloc] init];

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	[self setupBannerView];
#endif		
	
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
	[htmlDetailsController release];
	[parseErrorController release];
	[currentFile release];
	[columnNamesForFileName release];
	[indexPathForFileName release];
	[searchStringForFileName release];
	[importantColumnIndexes release];
	[_preDefinedHiddenColumns release];
	
	if( rawColumnIndexes )
		free(rawColumnIndexes);
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	self.bannerView.delegate = nil;
#endif	
	
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
		[s appendFormat:@"Wrong number of objects in row(s). Potentially first problematic row:\n\n%@\n\n", file.problematicRow];
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
	// Note that the actual animation of the activity view won't stop until this callback is done
	[[CSV_TouchAppDelegate sharedInstance] slowActivityCompleted];
	
	if( currentFile != selectedFile )
	{
		BOOL parsedOK = [self selectFile:selectedFile];
		
		if( !parsedOK )
		{
			showingRawString = NO;
			[[parseErrorController textView] setText:[CSVDataViewController parseErrorStringForFile:currentFile]];
			[self pushViewController:parseErrorController animated:YES];
			return;			
		}
		[[itemController tableView] deselectRowAtIndexPath:[[itemController tableView] indexPathForSelectedRow]
												  animated:NO];
		[itemController dataLoaded];
	}
	
	// Check if there seems to be a problem with the file preventing us from reading it
	if( [[currentFile itemsWithResetShortdescriptions:NO] count] < 1 ||
	   [[currentFile availableColumnNames] count] == 0 ||
	   ([[currentFile availableColumnNames] count] == 1 && [CSVPreferencesController showDebugInfo]) )
	{
		showingRawString = NO;
		[[parseErrorController textView] setText:[CSVDataViewController parseErrorStringForFile:currentFile]];
		[self pushViewController:parseErrorController animated:YES];
	}
	else
	{
		// We could read the file and will display it, but we should also check if we have any other problems
		// Check if something seems screwy...
		if( [importantColumnIndexes count] == 0 && [itemController.objects count] > 1 )
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No columns to show!"
															 message:@"Probably reason: File refreshed but column names have changed. Please click Edit -> Reset Columns"
															delegate:[[UIApplication sharedApplication] delegate]
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];		
		}
		else if( [CSVPreferencesController showDebugInfo] )
		{
			if( currentFile.droppedRows > 0 )
			{
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Dropped Rows!"
																 message:[NSString stringWithFormat:@"%d rows dropped due to problems reading them. Last dropped row:\n%@",
																		  currentFile.droppedRows, currentFile.problematicRow]
																delegate:[[UIApplication sharedApplication] delegate]
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil] autorelease];
				[alert show];
			}
			else if([[currentFile availableColumnNames] count] != 
					[[NSSet setWithArray:[currentFile availableColumnNames]] count] )
			{
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Identical Column Titles!"
																 message:@"Some of the columns have the same title; this should be changed for correct functionality. Please make sure the first line in the file consists of the column titles."
																delegate:[[UIApplication sharedApplication] delegate]
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil] autorelease];
				[alert show];
			}
		}
		[self pushViewController:itemController animated:YES];
	}
}

- (IBAction) toggleDetailsView:(id)sender
{
	if( [self currentDetailsController] == fancyDetailsController )
	{
		[self popViewControllerAnimated:NO];
		[self pushViewController:htmlDetailsController animated:NO];
	}
	else if( [self currentDetailsController] == htmlDetailsController )
	{
		[self popViewControllerAnimated:NO];
		[self pushViewController:detailsController animated:NO];
	}	
	else if( [self currentDetailsController] == detailsController )
	{
		[self popViewControllerAnimated:NO];
		[self pushViewController:fancyDetailsController animated:NO];
	}	
	selectedDetailsView = (selectedDetailsView+1) % 3;
}

- (UIBarButtonItem *) refreshFilesItem
{
	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																			 target:self 
																			 action:@selector(toggleRefreshFiles:)] autorelease];
	button.style = UIBarButtonItemStyleBordered;
	return button;
}

- (UIBarButtonItem *) showFileInfoItem
{
	return [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"]
											 style:UIBarButtonItemStyleBordered
											target:self 
											action:@selector(toggleShowFileInfo:)] autorelease];
}

- (UIBarButtonItem *) editFilesItem
{
	return [[[UIBarButtonItem alloc] initWithTitle:@"Edit"
											 style:UIBarButtonItemStyleBordered
											target:self 
											action:@selector(toggleEditFiles)] autorelease];
}

- (UIBarButtonItem *) doneItemWithSelector:(SEL)selector
{
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
														  target:self 
														  action:selector] autorelease];
}

- (void) searchStart
{
	searchInputInProgress = TRUE;
	itemController.useIndexes = FALSE;
	[itemController refreshIndexes];
	[itemController dataLoaded];
	//	[UIView beginAnimations:nil context:NULL];
	//	[UIView setAnimationDuration:0.5];
	//	itemController.tableView.alpha = 0.5;
	//	[UIView commitAnimations];
	
	[itemController.navigationItem setRightBarButtonItem:[self doneItemWithSelector:@selector(searchItems:)] animated:YES];
	[itemController.navigationItem setHidesBackButton:YES animated:YES];
	
//	[self.searchBar becomeFirstResponder];
}

- (void) searchFinish
{
	if( searchInputInProgress )
	{
		searchInputInProgress = FALSE;
		//	[UIView beginAnimations:nil context:NULL];
		//	[UIView setAnimationDuration:0.5];
		//	[self.searchBar removeFromSuperview];
		//	itemController.tableView.alpha = 1;
		//	CGRect tableViewFrame = itemController.tableView.frame;
		//	tableViewFrame.origin.y = 0;
		//	itemController.tableView.frame = tableViewFrame;
		//	[UIView commitAnimations];
		
		[itemController.navigationItem setHidesBackButton:NO animated:YES];
		[itemController.navigationItem setRightBarButtonItem:modificationDateButton animated:YES];
		if( [CSVPreferencesController useGroupingForItems] )
		{
			itemController.useIndexes = TRUE;
			[itemController refreshIndexes];
			[itemController dataLoaded];
		}
		NSUInteger path[2];
		if( itemController.useIndexes )
			path[0] = 1;
		else 
			path[0] = 0;
		path[1] = 0;
		if( [itemController itemExistsAtIndexPath:[NSIndexPath indexPathWithIndexes:path length:2]] )
			[itemController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:path length:2]
											atScrollPosition:UITableViewScrollPositionTop
													animated:YES];
		
		[self editDone:self];
	}
}

- (IBAction) searchItems:(id)sender
{
	[self searchFinish];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self searchStart];	
}

- (void)searchBar:(UISearchBar *)modifiedSearchBar textDidChange:(NSString *)searchText
{
	if( [[currentFile itemsWithResetShortdescriptions:NO] count] < [CSVPreferencesController maxNumberOfItemsToLiveFilter] )
		[self refreshObjectsWithResorting:NO];
	else
		itemsNeedFiltering = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self searchFinish];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self searchFinish];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	[self searchFinish];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL resetSearch = NO;
	if( searchInputInProgress )
	{
		[self searchFinish];
		if( [CSVPreferencesController clearSearchWhenQuickSelecting] )
			resetSearch = YES;
	}
	
	if( tableView == [itemController tableView] )
	{
		[self selectDetailsForRow:[itemController indexForObjectAtIndexPath:indexPath]];
		[self pushViewController:[self currentDetailsController] animated:YES];
	}
	else if( tableView == [fileController tableView] )
	{
		if( refreshingFilesInProgress )
		{
			[[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:[(CSVFileParser *)[[fileController objects] objectAtIndex:indexPath.row] URL]];
		}
		else if( showingFileInfoInProgress )
		{
			[[CSV_TouchAppDelegate sharedInstance] showFileInfo:(CSVFileParser *)[[fileController objects] objectAtIndex:indexPath.row]];
		}
		else
		{
			CSVFileParser *selectedFile = [[fileController objects] objectAtIndex:indexPath.row];
			
			if( selectedFile != currentFile && !selectedFile.hasBeenSorted )
			{
				[[CSV_TouchAppDelegate sharedInstance] slowActivityStarted];
			}
			[self performSelector:@selector(delayedPushItemController:)
					   withObject:selectedFile
					   afterDelay:0];
		}
	}
	else if( tableView == [fancyDetailsController tableView] )
	{
		NSArray *words = [[fancyDetailsController.objects objectAtIndex:
						   [fancyDetailsController indexForObjectAtIndexPath:indexPath]]
						  componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		for(NSString *word in words)
		{
			if( [word containsURL] )
			{
				[self delayedHtmlClick:[NSURL URLWithString:word]];
			}
			else if( [word containsMailAddress] )
			{
				[self delayedHtmlClick:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", word]]];
			}
		}
	}
	
	if( resetSearch )
	{
		searchBar.text = @"";
		CSVRow *selectedItem = [[itemController objects] objectAtIndex:[itemController indexForObjectAtIndexPath:indexPath]];
		[self refreshObjectsWithResorting:NO];
		NSUInteger newPosition = [[currentFile itemsWithResetShortdescriptions:NO] indexOfObject:selectedItem];
		if( newPosition != NSNotFound )
		{
			NSIndexPath *newPath = [itemController indexPathForObjectAtIndex:newPosition];
			if( newPath )
			{
				[itemController.tableView selectRowAtIndexPath:newPath
													  animated:NO
												scrollPosition:UITableViewScrollPositionTop];
				[self updateBadgeValueUsingItem:[[self currentDetailsController] navigationItem]
										   push:YES];
			}
		}
	}
	
}

- (IBAction) editColumns:(id)sender
{
	if( [CSVPreferencesController useBlackTheme] )
	{
		editNavigationBar.barStyle = UIBarStyleBlackOpaque;
	}
	
	[self presentModalViewController:editController animated:YES];
}

- (IBAction) editDone:(id)sender
{
	[searchBar endEditing:YES];
	//	if( searchBar.text && ![searchBar.text isEqualToString:@""] )
	//		searchButton.style = UIBarButtonItemStyleDone;
	//	else
	//		searchButton.style = UIBarButtonItemStylePlain;
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

- (void) passwordWasChecked
{
	if( [self topViewController] == fileController &&
	   [fileController.tableView indexPathForSelectedRow] != nil )
		[self tableView:fileController.tableView
didSelectRowAtIndexPath:[fileController.tableView indexPathForSelectedRow]];
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
	[[itemController objects] sortUsingSelector:[CSVRow compareSelector]];
	[itemController refreshIndexes];
	[itemController dataLoaded];
}

- (void) removeFileWithName:(NSString *)name
{
	for( CSVFileParser *oldFile in [fileController objects] )
	{
		if( [name isEqualToString:[oldFile fileName]] )
		{
			[[fileController objects] removeObject:oldFile];
			return;
		}
	}
}

- (void) newFileDownloaded:(CSVFileParser *)newFile
{
	[self removeFileWithName:[newFile fileName]];
	newFile.hasBeenDownloaded = TRUE;
	[[fileController objects] addObject:newFile];
	[[fileController objects] sortUsingSelector:@selector(compareFileName:)];
	[fileController dataLoaded];
	if( [self topViewController] == fileController )
		[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
}

- (NSUInteger) indexOfFilesToolbarItemWithSelector:(SEL)selector
{
	NSUInteger index = 0;
	for( UIBarButtonItem *item in [self.filesToolbar items] )
	{
		if( item.action == selector )
			return index;
		index++;
	}
	
	return NSNotFound;
}

- (IBAction) toggleRefreshFiles:(id)sender
{
	if( showingFileInfoInProgress || editFilesInProgress )
		return;
	
	refreshingFilesInProgress = !refreshingFilesInProgress;
	NSUInteger index = [self indexOfFilesToolbarItemWithSelector:@selector(toggleRefreshFiles:)];
	
	if( index == NSNotFound )
		return;
	
	if( refreshingFilesInProgress )
	{
		fileController.removeDisclosure = YES;
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:index
						 withObject:[self doneItemWithSelector:@selector(toggleRefreshFiles:)]];
		self.filesToolbar.items = items;
	}
	else
	{
		fileController.removeDisclosure = NO;
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:index withObject:[self refreshFilesItem]];
		self.filesToolbar.items = items;
	}
	[fileController dataLoaded];
}

- (IBAction) refreshAllFiles:(id)sender
{
	[[CSV_TouchAppDelegate sharedInstance] reloadAllFiles];
}

- (IBAction) loadFileList
{
	[[CSV_TouchAppDelegate sharedInstance] loadFileList];
}

- (IBAction) toggleShowFileInfo:(id)sender
{
	if( editFilesInProgress || refreshingFilesInProgress )
		return;
	
	showingFileInfoInProgress = !showingFileInfoInProgress;
	NSUInteger index = [self indexOfFilesToolbarItemWithSelector:@selector(toggleShowFileInfo:)];

	if( index == NSNotFound )
		return;

	if( showingFileInfoInProgress )
	{
		fileController.removeDisclosure = YES;
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:index withObject:[self doneItemWithSelector:@selector(toggleShowFileInfo:)]];
		self.filesToolbar.items = items;
		if( [fileController.tableView indexPathForSelectedRow] != nil )
			[self tableView:fileController.tableView didSelectRowAtIndexPath:
			 [fileController.tableView indexPathForSelectedRow]];
	}
	else
	{
		fileController.removeDisclosure = NO;
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:index withObject:[self showFileInfoItem]];
		self.filesToolbar.items = items;
	}
	[fileController dataLoaded];
}

- (IBAction) toggleEditFiles
{
	if( showingFileInfoInProgress || refreshingFilesInProgress )
		return;
	
	editFilesInProgress = !editFilesInProgress;
	if( editFilesInProgress )
	{
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:0 withObject:[self doneItemWithSelector:@selector(toggleEditFiles)]];
		self.filesToolbar.items = items;
		[[fileController tableView] setEditing:YES animated:YES];
	}
	else
	{
		NSMutableArray *items = [NSMutableArray arrayWithArray:[self.filesToolbar items]];
		[items replaceObjectAtIndex:0 withObject:[self editFilesItem]];
		self.filesToolbar.items = items;
		[[fileController tableView] setEditing:NO animated:YES];
	}
}

- (IBAction) nextDetailsClicked:(id)sender
{
	NSIndexPath *selectedRow = [[itemController tableView] indexPathForSelectedRow];                                              // return nil or index path representing section and row of selection.
	if( selectedRow  )
	{
		NSUInteger newIndex;
		if( [[itemController objects] count] > [itemController indexForObjectAtIndexPath:selectedRow]+1 )
			newIndex = [itemController indexForObjectAtIndexPath:selectedRow] + 1;
		else if( [[itemController objects] count] == [itemController indexForObjectAtIndexPath:selectedRow]+1 )
			newIndex = 0;
		else
			return;
		NSIndexPath *newIndexPath = [itemController indexPathForObjectAtIndex:newIndex];
		[[itemController tableView] selectRowAtIndexPath:newIndexPath
												animated:NO
										  scrollPosition:UITableViewScrollPositionMiddle];
		[self selectDetailsForRow:newIndex];
	}
}

- (IBAction) previousDetailsClicked:(id)sender
{
	NSIndexPath *selectedRow = [[itemController tableView] indexPathForSelectedRow];                                              // return nil or index path representing section and row of selection.
	if( selectedRow  )
	{
		NSUInteger newIndex;
		if( [itemController indexForObjectAtIndexPath:selectedRow] > 0 )
			newIndex = [itemController indexForObjectAtIndexPath:selectedRow] - 1;
		else if( [itemController indexForObjectAtIndexPath:selectedRow] == 0 )
			newIndex = [[itemController objects] count] - 1;
		else
			return;
		NSIndexPath *newIndexPath = [itemController indexPathForObjectAtIndex:newIndex];
		[[itemController tableView] selectRowAtIndexPath:newIndexPath
												animated:NO
										  scrollPosition:UITableViewScrollPositionMiddle];
		[self selectDetailsForRow:newIndex];
	}
}

- (void) swipe:(UIView *) swipeView rightSwipe:(BOOL)rightSwipe
{
	if( [CSVPreferencesController useDetailsNavigation] && [CSVPreferencesController useDetailsSwipe] )
	{
		if( [CSVPreferencesController useSwipeAnimation] )
		{
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.25];
			if( [[self currentDetailsController] respondsToSelector:@selector(contentView)] )
				[[(OzyRotatableViewController *)[self currentDetailsController] contentView] setAlpha:0.5];
			else
				[[[self currentDetailsController] view] setAlpha:0.5];
			[UIView commitAnimations];
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.25];
			if( [[self currentDetailsController] respondsToSelector:@selector(contentView)] )
				[[(OzyRotatableViewController *)[self currentDetailsController] contentView] setAlpha:1];
			else
				[[[self currentDetailsController] view] setAlpha:1];
		}
		if( rightSwipe )
			[self nextDetailsClicked:nil];
		else
			[self previousDetailsClicked:nil];
		if( [CSVPreferencesController useSwipeAnimation] )
			[UIView commitAnimations];
	}
}
   
- (void) rightSwipe:(UIView *) swipeView
{
	[self swipe:swipeView rightSwipe:YES];
}

- (void) leftSwipe:(UIView *) swipeView
{
	[self swipe:swipeView rightSwipe:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if(self.visibleViewController == htmlDetailsController ||
	   self.visibleViewController == fancyDetailsController ||
	   self.visibleViewController == detailsController)
	{
		[self updateHtmlViewWithItem:_latestShownItem];
		[fancyDetailsController.tableView reloadData];
	}
	else if( self.visibleViewController == itemController )
		[itemController.tableView reloadData];
	else if( self.visibleViewController == fileController )
		[fileController.tableView reloadData];
}


@end

@interface CSVDataViewController (OzymandiasViewControllerViewDelegate) <OzymandiasViewControllerViewDelegate>
@end

@implementation CSVDataViewController (OzymandiasViewControllerViewDelegate)

- (void) addNavigationButtonsToView:(UIViewController *)controller
{
	UIView *contentView = ([controller respondsToSelector:@selector(contentView)] ?
					[(OzyRotatableViewController *)controller contentView] : [controller view]);
	CGSize viewSize = contentView.frame.size;
	CGSize buttonSize = nextDetails.frame.size; // We assume both buttons have the same size already
	CGFloat toolbarOffset = 44;//([CSVPreferencesController showDetailsToolbar] ? 44 : 0);
	previousDetails.frame = CGRectMake(0,
									   viewSize.height-buttonSize.height-16-toolbarOffset,
									   buttonSize.width, buttonSize.height);
	nextDetails.frame = CGRectMake(viewSize.width-buttonSize.width,
								   viewSize.height-buttonSize.height-16-toolbarOffset,
								   buttonSize.width, buttonSize.height);
	[contentView addSubview:nextDetails];
	[contentView addSubview:previousDetails];
}

// A little bit hacky, this one...
- (void) removeNavigationButtonsFromView:(UIViewController *)controller
{
	UIView *contentView = ([controller respondsToSelector:@selector(contentView)] ?
						   [(OzyRotatableViewController *)controller contentView] : [controller view]);
	for( UIView *view in [contentView subviews] )
	{
		if( [view isKindOfClass:[UIButton class]] &&
		   ([view isEqual:previousDetails] || [view isEqual:nextDetails]) )
		{
			[view removeFromSuperview];
		}
	}
}

- (void) viewDidAppear:(UIView *)view controller:(UIViewController *)controller
{
	if( [CSVPreferencesController useDetailsNavigation] )
	{
		if( controller == htmlDetailsController || ![CSVPreferencesController useDetailsSwipe] )
		{
			[self addNavigationButtonsToView:controller];
		}
	}
}

- (void) viewDidDisappear:(UIView *)view controller:(UIViewController *)controller
{
	if( [CSVPreferencesController useDetailsNavigation] )
	{	
		if( controller == htmlDetailsController || ![CSVPreferencesController useDetailsSwipe] )
		{
			[self removeNavigationButtonsFromView:controller];
		}
	}
}

@end

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@implementation CSVDataViewController (AdBannerViewDelegate)

-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2 : 0.0;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0;
	NSString *contentSizeIdentifier;
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		if ([CSVPreferencesController canUseAbstractBannerNames] )
			contentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
		else
			contentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
	}
    else
	{
		if ([CSVPreferencesController canUseAbstractBannerNames] )
			contentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
		else
			contentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
	}
	self.bannerView.currentContentSizeIdentifier = contentSizeIdentifier;
	bannerHeight = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSizeIdentifier].height;
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    // This layout is for an ad at the bottom of the view.
    if(self.bannerView.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    }
    else
    {
		bannerOrigin.y += bannerHeight;
    }
    
	
    // And finally animate the changes, running layout for the content view if required.
    [UIView animateWithDuration:animationDuration
                     animations:^{
						 self.contentView.frame = contentFrame;
						 [self.contentView layoutIfNeeded];
						 self.bannerView.frame = CGRectMake(bannerOrigin.x,
															bannerOrigin.y,
															self.bannerView.frame.size.width,
															self.bannerView.frame.size.height);
					 }
	 ];
}


- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if (!self.bannerIsVisible)
    {
		[self layoutForCurrentOrientation:YES];
		self.bannerIsVisible = NO;
	}
}	

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if (self.bannerIsVisible)
    {
		[self layoutForCurrentOrientation:YES];
		self.bannerIsVisible = NO;
	}
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	// We have no restrictions about when we can leave app or not, and nothing to stop
	return YES;
}	

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	// Nothing for us to do here
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										duration:(NSTimeInterval)duration
{
	[self layoutForCurrentOrientation:NO];
}

@end
#endif

