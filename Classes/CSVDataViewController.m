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

#define NORMAL_SORT_ORDER @"▼"
#define REVERSE_SORT_ORDER @"▲"

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

@implementation CSVDataViewController

@synthesize searchBar = _searchBar;
@synthesize showDeletedColumns = _showDeletedColumns;
@synthesize contentView = _contentView;

- (FilesViewController *) fileController
{
    return fileController;
}

- (ParseErrorViewController *) parseErrorController
{
    return parseErrorController;
}

- (CSVFileParser *) currentFile
{
	return currentFile;
}

- (NSArray *) files
{
	return [fileController objects];
}

- (NSUInteger) numberOfFiles
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
	NSMutableArray *allObjects = [[self currentFile] itemsWithResetShortdescriptions:needsResorting];
	NSMutableArray *filteredObjects = [NSMutableArray array];
	NSMutableArray *workObjects;
	NSString *searchString = [self.searchBar.text lowercaseString];
	
	// We should always resort all objects, no matter which are actually shown
	if( needsResorting &&
	   ([CSVPreferencesController maxNumberOfItemsToSort] == 0 ||
		[allObjects count] <= [CSVPreferencesController maxNumberOfItemsToSort]) )
	{
		[allObjects sortUsingSelector:[CSVRow compareSelector]];
		[self currentFile].hasBeenSorted = YES;
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
	
	[self.itemController setObjects:workObjects];
	[self.itemController dataLoaded];
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
	NSArray *availableColumns = [[self currentFile] availableColumnNames];
	[importantColumnIndexes removeAllObjects];
	if( rawColumnIndexes )
		free(rawColumnIndexes);
	for( NSString *usedColumn in [editController objects] )
	{
		for( NSUInteger i = 0 ; i < [availableColumns count] ; i++ )
			if( [usedColumn isEqualToString:[availableColumns objectAtIndex:i]] )
				[importantColumnIndexes addObject:[NSNumber numberWithUnsignedInteger:i]];
	}
	rawColumnIndexes = malloc(sizeof(int) * [importantColumnIndexes count]);
	for( int i = 0 ; i < [importantColumnIndexes count] ; i++ )
		rawColumnIndexes[i] = [[importantColumnIndexes objectAtIndex:i] intValue];
}

- (void) updateColumnNamesForFile:(CSVFileParser *)file
{
	NSArray *names = [columnNamesForFileName objectForKey:[file fileName]];
	if( !names )
	{
		NSArray *availableNames = [file availableColumnNames];
		// Do we have any predefined hidden columns?
		NSIndexSet *hidden = [_preDefinedHiddenColumns objectForKey:[file fileName]];
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
			names = [file availableColumnNames];
		}
		[_preDefinedHiddenColumns removeObjectForKey:[file fileName]];
		[columnNamesForFileName setObject:names forKey:[file fileName]];
	}
    if( [[file fileName] isEqualToString:[[self currentFile] fileName]])
    {
        [editController setObjects:[NSMutableArray arrayWithArray:names]];
        [editController dataLoaded];
        [self updateColumnIndexes];
    }
}

- (void) cacheCurrentFileData
{
	if( [self currentFile] )
	{
		NSArray *a = [self.itemController.tableView indexPathsForVisibleRows];
		if( [a count] > 0 )
			[indexPathForFileName setObject:[[a objectAtIndex:0] dictionaryRepresentation] forKey:[[self currentFile] fileName]];
		else
			[indexPathForFileName removeObjectForKey:[[self currentFile] fileName]];
		if( self.searchBar.text && ![self.searchBar.text isEqualToString:@""] )
			[searchStringForFileName setObject:self.searchBar.text forKey:[[self currentFile] fileName]];
		else
			[searchStringForFileName removeObjectForKey:[[self currentFile] fileName]];
	}
}

- (BOOL) selectFile:(CSVFileParser *)file
{
    // Store current position of itemController and search string
    [self cacheCurrentFileData];
    
    currentFile = file;
    [[self currentFile] parseIfNecessary];
    
    if( !currentFile.rawString )
    {
        return FALSE;
    }
    NSString *cachedSearchString = [searchStringForFileName objectForKey:[currentFile fileName]];
    if( cachedSearchString )
        self.searchBar.text = cachedSearchString;
    else
        self.searchBar.text = @"";
    [self updateColumnNamesForFile:currentFile];
    [self.itemController setTitle:[currentFile defaultTableViewDescription]];
    [self refreshObjectsWithResorting:!currentFile.hasBeenSorted];
    
    // Reset last known position of items
    // First scroll to top, if we don't find any setting
    [self.itemController.tableView scrollToTopWithAnimation:NO];
    NSDictionary *indexPathDictionary = [indexPathForFileName objectForKey:[currentFile fileName]];
    if( [indexPathDictionary isKindOfClass:[NSDictionary class]] )
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathWithDictionary:indexPathDictionary];
        if( [self.itemController itemExistsAtIndexPath:indexPath] )
        {
            [[self.itemController tableView] scrollToRowAtIndexPath:indexPath
                                              atScrollPosition:UITableViewScrollPositionTop
                                                      animated:NO];
        }
    }
    return TRUE;
}


- (void) delayedPushItemController:(CSVFileParser *)selectedFile
{
    // Note that the actual animation of the activity view won't stop until this callback is done
    [[CSV_TouchAppDelegate sharedInstance] slowActivityCompleted];
    
    // Don't check if current file == selected file; this will happen very rarely,
    // and if user has e.g. changed file encoding we need to reparse etc anyways
    BOOL parsedOK = [self selectFile:selectedFile];
    
    if( !parsedOK )
    {
        [[[self parseErrorController] textView] setText:[[self currentFile] parseErrorString]];
        [self.navController pushViewController:[self parseErrorController] animated:YES];
        return;
    }
    
    [[self.itemController tableView] deselectRowAtIndexPath:[[[self itemController] tableView] indexPathForSelectedRow]
                                                                                       animated:NO];
    [self.itemController dataLoaded];
    
    // Check if there seems to be a problem with the file preventing us from reading it
    if( [[[self currentFile] itemsWithResetShortdescriptions:NO] count] < 1 ||
       [[[self currentFile] availableColumnNames] count] == 0 ||
       ([[[self currentFile] availableColumnNames] count] == 1 && [CSVPreferencesController showDebugInfo]) )
    {
        [[[self parseErrorController] textView] setText:[[self currentFile] parseErrorString]];
        [self.navController pushViewController:[self parseErrorController] animated:YES];
    }
    else
    {
        // We could read the file and will display it, but we should also check if we have any other problems
        // Check if something seems screwy...
        if( [importantColumnIndexes count] == 0 && [[self itemController].objects count] > 1 )
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No columns to show!"
                                                                           message:@"Probably reason: File refreshed but column names have changed. Please click Edit -> Reset Columns"
                                                                     okButtonTitle:@"OK"
                                                                         okHandler:nil];
            [self.navController.topViewController presentViewController:alert
                                                               animated:YES
                                                             completion:nil];
        }
        else if( [CSVPreferencesController showDebugInfo] )
        {
            if( [self currentFile].droppedRows > 0 )
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dropped Rows!"
                                                                               message:[NSString stringWithFormat:@"%d rows dropped due to problems reading them. Last dropped row:\n%@",
                                                                                        [self currentFile].droppedRows,
                                                                                        [self currentFile].problematicRow]
                                                                         okButtonTitle:@"OK"
                                                                             okHandler:nil];
                [self.navController.topViewController presentViewController:alert
                                                                   animated:YES
                                                                 completion:nil];

            }
            else if([[[self currentFile] availableColumnNames] count] !=
                    [[NSSet setWithArray:[[self currentFile] availableColumnNames]] count] )
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Identical Column Titles!"
                                                                               message:@"Some of the columns have the same title; this should be changed for correct functionality. Please make sure the first line in the file consists of the column titles."
                                                                         okButtonTitle:@"OK"
                                                                             okHandler:nil];
                [self.navController.topViewController presentViewController:alert
                                                                   animated:YES
                                                                 completion:nil];
            }
        }
        [self.itemController setFile:[self currentFile]];
        [self.navController pushViewController:[self itemController] animated:YES];
    }
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

+ (NSString *) sandboxedFileURLFromLocalURL:(NSString *) localURL
{
    // We assume that the localURL has already been checked for a true local file URL
    NSArray *tmpArray = [localURL componentsSeparatedByString:@"file://"];
    if( [tmpArray count] == 2 )
    {
        NSMutableString *s = [NSMutableString string];
        [s appendString:@"file://"];
        [s appendString:[[CSV_TouchAppDelegate localMediaDocumentsPath] stringByAppendingPathComponent:[tmpArray objectAtIndex:1]]];
        return s;
    }
    else
        return localURL;
}

- (void) updateBadgeValueUsingItem:(UINavigationItem *)item push:(BOOL)push
{
	NSUInteger count = 0;
	
	// Details controller will be visible
	if(push &&
	   (item == detailsController.navigationItem ||
		item == fancyDetailsController.navigationItem ||
		item == htmlDetailsController.navigationItem))
	{
		NSIndexPath *selectedRow = [self.itemController.tableView indexPathForSelectedRow];
		if( selectedRow &&
		   [self.itemController indexForObjectAtIndexPath:selectedRow] != NSNotFound )
		{
			count = [self.itemController indexForObjectAtIndexPath:selectedRow] + 1;
		}
		else
		{
			count = 0;
		}
		NSString *s = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)count, (unsigned long)[[self.itemController objects] count]];
		detailsController.title = s;
		fancyDetailsController.title = s;
		htmlDetailsController.title = s;
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
	if( [[[self currentFile] availableColumnNames] count] > [importantColumnIndexes count] )
	{
		NSArray *sectionStarts = [NSArray arrayWithObjects:
								  [NSNumber numberWithInt:0],
								  [NSNumber numberWithUnsignedInteger:[importantColumnIndexes count]],
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
			else if( [[d objectForKey:VALUE_KEY] containsLocalImageURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<td><img src=\"%@\"></img>", [CSVDataViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
			else if( [[d objectForKey:VALUE_KEY] containsLocalMovieURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<td><video src=\"%@\" controls x-webkit-airplay=\"allow\"></video>", [CSVDataViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
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
				[data appendFormat:@"<br><img src=\"%@\"></img><br>", [d objectForKey:VALUE_KEY]];
			else if( [[d objectForKey:VALUE_KEY] containsLocalImageURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<br><img src=\"%@\"></img><br>", [CSVDataViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
			else if( [[d objectForKey:VALUE_KEY] containsLocalMovieURL] && [CSVPreferencesController showInlineImages] )
				[data appendFormat:@"<br><video src=\"%@\" controls x-webkit-airplay=\"allow\"></video><br>", [CSVDataViewController sandboxedFileURLFromLocalURL:[d objectForKey:VALUE_KEY]]];
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
	if( [[self.itemController objects] count] > row )
		_latestShownItem = [[self.itemController objects] objectAtIndex:row];
	else
		_latestShownItem = nil;
	
	[self updateSimpleViewWithItem:_latestShownItem];
	[self updateEnhancedViewWithItem:_latestShownItem];
	[self updateHtmlViewWithItem:_latestShownItem];
	[self updateBadgeValueUsingItem:[[self currentDetailsController] navigationItem] push:YES];
}

- (void) delayedHtmlClick:(NSURL *)URL
{
	if( [CSVPreferencesController confirmLink] )
	{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Leave %@",
                                                                                ([CSVPreferencesController restrictedDataVersionRunning] ? @"CSV Lite" : @"CSV Touch")]
                                                                       message:[NSString stringWithFormat:@"Continue opening %@?", [URL absoluteString]]
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:^(UIAlertAction *action) {
                                                                         [[UIApplication sharedApplication] openURL:URL];
                                                                     }
                                                             cancelButtonTitle:@"Cancel"
                                                                 cancelHandler:nil];
        [self.navController.topViewController presentViewController:alert
                                                           animated:YES
                                                         completion:nil];        
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Load error!"
                                                                       message:[NSString stringWithFormat:@"Error when loading view. Description: %@\nCode: %ld",
                                                                                [error localizedDescription], (long)[error code]]
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:nil];
        [self.navController.topViewController presentViewController:alert
                                                           animated:YES
                                                         completion:nil];
	}
}

#define DEFS_COLUMN_NAMES @"defaultColumnNames"
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
	
    // Create a navigation controller and set as root
    self.navController = [[UINavigationController alloc] initWithRootViewController:fileController];
    
	// Setup stuff for controllers which can't be configured using InterfaceBuilder
	fancyDetailsController.size = [CSVPreferencesController detailsTableViewSize];
    	
	// Disable phone links, if desired
	if( [CSVPreferencesController enablePhoneLinks] == FALSE )
		[htmlDetailsController.webView setDataDetectorTypes:UIDataDetectorTypeLink];
	
	// Searchbar setup
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,170,320,44)];
    self.searchBar = searchBar;
    [searchBar setDelegate:self];
	self.itemController.tableView.tableHeaderView = searchBar;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.placeholder = @"Search items";
	
	[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
    
	// Read last state to be able to get back to where we were before quitting last time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// 0. Extra settings
	selectedDetailsView = (int)[defaults integerForKey:DEFS_SELECTED_DETAILS_VIEW];
	
	// 1. Read in the saved columns & order of them for each file; similarly for search strings, positions, etc
	NSDictionary *defaultNames = [defaults objectForKey:DEFS_COLUMN_NAMES];
	if( defaultNames && [defaultNames isKindOfClass:[NSDictionary class]] )
	{
		columnNamesForFileName = [[NSMutableDictionary alloc] initWithDictionary:defaultNames];
	}
	NSDictionary *itemPositions = [defaults objectForKey:DEFS_ITEM_POSITIONS_FOR_FILES];
	if( itemPositions && [itemPositions isKindOfClass:[NSDictionary class]] )
	{
		indexPathForFileName = [[NSMutableDictionary alloc] initWithDictionary:itemPositions];
	}
	NSDictionary *searchStrings = [defaults objectForKey:DEFS_SEARCH_STRINGS_FOR_FILES];
	if( searchStrings && [searchStrings isKindOfClass:[NSDictionary class]] )
	{
		searchStringForFileName = [[NSMutableDictionary alloc] initWithDictionary:searchStrings];
	}
	
	// Also read in any predefined hidden columns
	NSDictionary *predefinedHiddenColumns = [defaults objectForKey:DEFS_PREDEFINED_HIDDEN_COLUMNS];
	if( predefinedHiddenColumns && [predefinedHiddenColumns isKindOfClass:[NSDictionary class]] )
	{
		_preDefinedHiddenColumns = [[NSMutableDictionary alloc] initWithDictionary:predefinedHiddenColumns];
	}
	
	// If starting up in emergency mode, we should not do anything more here
	if( emergencyMode )
		return;
	
	[self updateBadgeValueUsingItem:[self.navController topViewController].navigationItem push:YES];
}

- (void) fileWasSelected:(CSVFileParser *)file
{
    if( !file.hasBeenSorted )
    {
        [[CSV_TouchAppDelegate sharedInstance] slowActivityStarted];
    }
    [self performSelector:@selector(delayedPushItemController:)
               withObject:file
               afterDelay:0];
}

- (void) modifyItemsTableViewSize:(BOOL)increase
{
	if( [CSVPreferencesController modifyItemsTableViewSize:increase] )
	{
		NSArray *a = [self.itemController.tableView indexPathsForVisibleRows];
		NSIndexPath *oldIndexPath = nil;
		if( [a count] > 0 )
			oldIndexPath = [a objectAtIndex:0];
		self.itemController.size = [CSVPreferencesController itemsTableViewSize];
		if( oldIndexPath )
			[self.itemController.tableView scrollToRowAtIndexPath:oldIndexPath
											atScrollPosition:UITableViewScrollPositionTop
													animated:NO];
	}
}

- (IBAction) toggleShowHideDeletedColumns
{
	self.showDeletedColumns = !self.showDeletedColumns;
	[self updateSimpleViewWithItem:_latestShownItem];
	[self updateEnhancedViewWithItem:_latestShownItem];
	[self updateHtmlViewWithItem:_latestShownItem];
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
	importantColumnIndexes = [[NSMutableArray alloc] init];
	_preDefinedHiddenColumns = [[NSMutableDictionary alloc] init];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(tableViewContentChanged:)
												 name:OzyContentChangedInTableView
											   object:nil];
	return self;
}

- (void) saveColumnNames
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if( columnNamesForFileName )
    {
        [defaults setObject:columnNamesForFileName forKey:DEFS_COLUMN_NAMES];
        [defaults synchronize];
    }
}

- (void) resetColumnNamesForFile:(CSVFileParser *)file
{
    if( file && [file fileName])
    {
        [columnNamesForFileName removeObjectForKey:[file fileName]];
        [self updateColumnNamesForFile:file];
        itemsNeedResorting = YES;
        [self saveColumnNames];
    }
}

- (void) resetColumnNamesForCurrentFile
{
	[self resetColumnNamesForFile:[self currentFile]];
}

- (void) tableViewContentChanged:(NSNotification *)n
{
	if( [n object] == editController )
	{
		[columnNamesForFileName setObject:[editController objects] forKey:[[self currentFile] fileName]];
		[self updateColumnIndexes];
		itemsNeedResorting = YES;
        // Fix so that this is remembered even if app is forcefully terminated (DSI bug 2011-07-18)
        [self saveColumnNames];
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

- (void) gotoNextDetailsView
{
	if( [self currentDetailsController] == fancyDetailsController )
	{
		[self.navController popViewControllerAnimated:NO];
		[self.navController pushViewController:htmlDetailsController animated:NO];
	}
	else if( [self currentDetailsController] == htmlDetailsController )
	{
		[self.navController popViewControllerAnimated:NO];
		[self.navController pushViewController:detailsController animated:NO];
	}
	else if( [self currentDetailsController] == detailsController )
	{
		[self.navController popViewControllerAnimated:NO];
		[self.navController pushViewController:fancyDetailsController animated:NO];
	}
	selectedDetailsView = (selectedDetailsView+1) % 3;
}

- (UIBarButtonItem *) doneItemWithSelector:(SEL)selector
{
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
														  target:self
														  action:selector];
}

- (void) searchStart
{
	searchInputInProgress = TRUE;
	self.itemController.useIndexes = FALSE;
	[self.itemController refreshIndexes];
	[self.itemController dataLoaded];
	
	[self.itemController.navigationItem setRightBarButtonItem:[self doneItemWithSelector:@selector(searchItems:)] animated:YES];
	[self.itemController.navigationItem setHidesBackButton:YES animated:YES];
}

- (void) searchFinish
{
	if( searchInputInProgress )
	{
		searchInputInProgress = FALSE;
		
		[self.itemController.navigationItem setHidesBackButton:NO animated:YES];
		[self.itemController.navigationItem setRightBarButtonItem:self.itemController.modificationDateButton animated:YES];
		if( [CSVPreferencesController useGroupingForItems] )
		{
			self.itemController.useIndexes = TRUE;
			[self.itemController refreshIndexes];
			[self.itemController dataLoaded];
		}
		NSUInteger path[2];
		if( self.itemController.useIndexes )
			path[0] = 1;
		else
			path[0] = 0;
		path[1] = 0;
		if( [self.itemController itemExistsAtIndexPath:[NSIndexPath indexPathWithIndexes:path length:2]] )
			[self.itemController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:path length:2]
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

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    if( bar == self.searchBar)
    {
        return UIBarPositionTopAttached;
    }
    else
    {
        return UIBarPositionAny;
    }
}

- (void)searchBar:(UISearchBar *)modifiedSearchBar textDidChange:(NSString *)searchText
{
	if( [[[self currentFile] itemsWithResetShortdescriptions:NO] count] < [CSVPreferencesController maxNumberOfItemsToLiveFilter] )
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

- (void) selectedItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL resetSearch = NO;
    if( searchInputInProgress )
    {
        [self searchFinish];
        if( [CSVPreferencesController clearSearchWhenQuickSelecting] )
            resetSearch = YES;
    }
    
    [self selectDetailsForRow:[self.itemController indexForObjectAtIndexPath:indexPath]];
    [self.navController pushViewController:[self currentDetailsController] animated:YES];

    if( resetSearch )
    {
        self.searchBar.text = @"";
        CSVRow *selectedItem = [[self.itemController objects] objectAtIndex:[self.itemController indexForObjectAtIndexPath:indexPath]];
        [self refreshObjectsWithResorting:NO];
        NSUInteger newPosition = [[[self currentFile] itemsWithResetShortdescriptions:NO] indexOfObject:selectedItem];
        if( newPosition != NSNotFound )
        {
            NSIndexPath *newPath = [self.itemController indexPathForObjectAtIndex:newPosition];
            if( newPath )
            {
                [self.itemController.tableView selectRowAtIndexPath:newPath
                                                           animated:NO
                                                     scrollPosition:UITableViewScrollPositionTop];
                [self updateBadgeValueUsingItem:[[self currentDetailsController] navigationItem]
                                           push:YES];
            }
        }
    }
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( tableView == [fancyDetailsController tableView] )
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
}

- (IBAction) editColumns
{
	[self.navController pushViewController:editController animated:YES];
}

- (IBAction) editDone:(id)sender
{
	[self.searchBar endEditing:YES];
	if( itemsNeedResorting || itemsNeedFiltering )
	{
		[self refreshObjectsWithResorting:itemsNeedResorting];
		itemsNeedResorting = itemsNeedFiltering = NO;
	}
	[self updateBadgeValueUsingItem:self.itemController.navigationItem push:YES];
}

- (void) passwordWasChecked
{
	if( [self.navController topViewController] == fileController &&
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
	if( [self.navController topViewController] == fileController )
		[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
}

- (void) markFilesAsDirty
{
	for( CSVFileParser *fileParser in [fileController objects] )
		fileParser.hasBeenParsed = NO;
	[self updateColumnNamesForFile:[self currentFile]];
	[self refreshObjectsWithResorting:YES];
	[self updateBadgeValueUsingItem:[self.navController topViewController].navigationItem push:YES];
}

- (void) resortObjects
{
	[[self.itemController objects] sortUsingSelector:[CSVRow compareSelector]];
	[self.itemController refreshIndexes];
	[self.itemController dataLoaded];
}

- (void) removeFileWithName:(NSString *)name
{
	for( CSVFileParser *oldFile in [fileController objects] )
	{
		if( [name isEqualToString:[oldFile fileName]] )
		{
			[[fileController objects] removeObject:oldFile];
            [fileController.tableView reloadData];
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
	if( [self.navController topViewController] == fileController )
		[self updateBadgeValueUsingItem:fileController.navigationItem push:YES];
}

- (NSUInteger) indexOfToolbarItemWithSelector:(SEL)selector
{
    NSUInteger index = 0;
    for( UIBarButtonItem *item in [self.navController.toolbar items] )
    {
        if( item.action == selector )
            return index;
        index++;
    }
    
    return NSNotFound;
}

- (IBAction) nextDetailsClicked:(id)sender
{
	NSIndexPath *selectedRow = [self.itemController.tableView indexPathForSelectedRow];                                              // return nil or index path representing section and row of selection.
	if( selectedRow  )
	{
		NSUInteger newIndex;
		if( [[self.itemController objects] count] > [self.itemController indexForObjectAtIndexPath:selectedRow]+1 )
			newIndex = [self.itemController indexForObjectAtIndexPath:selectedRow] + 1;
		else if( [[self.itemController objects] count] == [self.itemController indexForObjectAtIndexPath:selectedRow]+1 )
			newIndex = 0;
		else
			return;
		NSIndexPath *newIndexPath = [self.itemController indexPathForObjectAtIndex:newIndex];
		[[self.itemController tableView] selectRowAtIndexPath:newIndexPath
												animated:NO
										  scrollPosition:UITableViewScrollPositionMiddle];
		[self selectDetailsForRow:newIndex];
	}
}

- (IBAction) previousDetailsClicked:(id)sender
{
	NSIndexPath *selectedRow = [self.itemController.tableView indexPathForSelectedRow];                                              // return nil or index path representing section and row of selection.
	if( selectedRow  )
	{
		NSUInteger newIndex;
		if( [self.itemController indexForObjectAtIndexPath:selectedRow] > 0 )
			newIndex = [self.itemController indexForObjectAtIndexPath:selectedRow] - 1;
		else if( [self.itemController indexForObjectAtIndexPath:selectedRow] == 0 )
			newIndex = [[self.itemController objects] count] - 1;
		else
			return;
		NSIndexPath *newIndexPath = [self.itemController indexPathForObjectAtIndex:newIndex];
		[[self.itemController tableView] selectRowAtIndexPath:newIndexPath
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
	if(self.navController.visibleViewController == htmlDetailsController ||
	   self.navController.visibleViewController == fancyDetailsController ||
	   self.navController.visibleViewController == detailsController)
	{
		[self updateHtmlViewWithItem:_latestShownItem];
		[fancyDetailsController.tableView reloadData];
	}
	else if( self.navController.visibleViewController == self.itemController )
		[self.itemController.tableView reloadData];
	else if( self.navController.visibleViewController == fileController )
		[fileController.tableView reloadData];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
