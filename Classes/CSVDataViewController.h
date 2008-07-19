//
//  CSVDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OzyTableViewController, CSVFileParser, OzyTextViewController;

@interface CSVDataViewController : UINavigationController <UITableViewDelegate>
{
	IBOutlet OzyTextViewController *detailsController;
	IBOutlet OzyTableViewController *itemController;
	IBOutlet OzyTableViewController *fileController;
	
	// For better GUI when things are slow...
	IBOutlet UIView *activityView;
	IBOutlet UIActivityIndicatorView *fileParsingActivityView;

	CSVFileParser *currentFile;
	BOOL itemsNeedResorting;
	BOOL itemsNeedFiltering;

	// Cached data for files
	NSMutableDictionary *columnNamesForFileName;
	NSMutableDictionary *indexPathForFileName;
	NSMutableDictionary *searchStringForFileName;

	// Edit view
	IBOutlet OzyTableViewController *editController;
	IBOutlet UISearchBar *searchBar;
	
	// An array with the current indexes to use for the items
	NSMutableArray *columnIndexes;
	int *rawColumnIndexes;
	
	BOOL refreshingFilesInProgress;
}

+ (CSVDataViewController *) sharedInstance;

- (IBAction) edit:(id)sender;
- (IBAction) editDone:(id)sender;
- (IBAction) resetColumnNames:(id)sender;
- (IBAction) toggleRefreshFiles:(id)sender;

- (void) setFiles:(NSArray *) files;

- (void) reparseFiles;
- (void) resortObjects;

- (void) newFileDownloaded:(CSVFileParser *)file;

- (NSArray *) columnIndexes;
- (int *) rawColumnIndexes;

- (void) setSize:(NSInteger)size;

- (void) applicationWillTerminate;
- (void) applicationDidFinishLaunching;

- (CSVFileParser *) currentFile;
@end
