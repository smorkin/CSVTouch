//
//  CSVDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OzyTableViewController,
CSVFileParser, 
OzyTextViewController,
OzyRotatableViewController;

@interface CSVDataViewController : UINavigationController <UITableViewDelegate>
{
	IBOutlet OzyTextViewController *detailsController;
	IBOutlet OzyTableViewController *fancyDetailsController;
	IBOutlet OzyRotatableViewController *htmlDetailsController;
	IBOutlet OzyTableViewController *itemController;
	IBOutlet OzyTableViewController *fileController;
	IBOutlet OzyTextViewController *parseErrorController;
	
	int selectedDetailsView; // 0 = fancy, 1 = web, 2 = simple
	IBOutlet UIButton *nextDetails;
	IBOutlet UIButton *previousDetails;
	
	CSVFileParser *currentFile;
	BOOL itemsNeedResorting;
	BOOL itemsNeedFiltering;

	// Cached data for files
	NSMutableDictionary *columnNamesForFileName;
	NSMutableDictionary *indexPathForFileName;
	NSMutableDictionary *searchStringForFileName;

	// Edit view
	IBOutlet OzyTableViewController *editController;
	IBOutlet UINavigationBar *editNavigationBar;
	
	// Search view
	IBOutlet UISearchBar *searchBar;
	IBOutlet UIBarButtonItem *searchButton;

	// Toolbars
	IBOutlet UIToolbar *itemsToolbar;
	IBOutlet UIBarButtonItem *enlargeItemsButton;
	IBOutlet UIBarButtonItem *shrinkItemsButton;
	IBOutlet UIBarButtonItem *itemsCountButton;
	IBOutlet UIToolbar *filesToolbar;
	IBOutlet UIBarButtonItem *filesCountButton;
	
	// An array with the current indexes to use for the items
	NSMutableArray *columnIndexes;
	int *rawColumnIndexes;
	
	BOOL refreshingFilesInProgress;
	BOOL showingFileInfoInProgress;
	BOOL editFilesInProgress;
	BOOL showingRawString;
}

@property (nonatomic, readonly) UIToolbar *itemsToolbar;
@property (nonatomic, readonly) UIToolbar *filesToolbar;
@property (nonatomic, readonly) UISearchBar *searchBar;

+ (CSVDataViewController *) sharedInstance;

- (IBAction) editColumns:(id)sender;
- (IBAction) editDone:(id)sender;
- (IBAction) resetColumnNames:(id)sender;
- (IBAction) toggleEditFiles;
- (IBAction) searchItems:(id)sender;
- (IBAction) toggleRefreshFiles:(id)sender;
- (IBAction) toggleShowFileInfo:(id)sender;
- (IBAction) toggleShowingRawString:(id)sender;
- (IBAction) toggleDetailsView:(id)sender;
- (IBAction) nextDetailsClicked:(id)sender;
- (IBAction) previousDetailsClicked:(id)sender;
- (IBAction) increaseTableViewSize;
- (IBAction) decreaseTableViewSize;

- (void) setFiles:(NSArray *) files;

- (void) markFilesAsDirty;
- (void) resortObjects;

- (void) newFileDownloaded:(CSVFileParser *)file;

- (NSArray *) columnIndexes;
- (int *) rawColumnIndexes;

- (void) applicationWillTerminate;
- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL) emergencyMode;

- (CSVFileParser *) currentFile;

- (int) numberOfFiles;
@end
