//
//  CSVDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#if defined(CSV_LITE)
#import <iAd/iAd.h>
#endif

#import "FilesViewController.h"
#import "ParseErrorViewController.h"
#import "ItemsViewController.h"
#import "EditViewController.h"

@class OzyTableViewController,
CSVFileParser, 
CSVRow,
OzyTextViewController,
OzyWebViewController;

@interface CSVDataViewController : UINavigationController <UITableViewDelegate, UISearchBarDelegate>
{
	IBOutlet OzyTextViewController *detailsController;
	IBOutlet OzyTableViewController *fancyDetailsController;
	IBOutlet OzyWebViewController *htmlDetailsController;
	IBOutlet ItemsViewController *itemController;
	IBOutlet FilesViewController *fileController;
	IBOutlet ParseErrorViewController *parseErrorController;
	
	int selectedDetailsView; // 0 = fancy, 1 = web, 2 = simple
	IBOutlet UIButton *nextDetails;
	IBOutlet UIButton *previousDetails;
	
	BOOL itemsNeedResorting;
	BOOL itemsNeedFiltering;

    CSVFileParser *currentFile;

	// Cached data for files
	NSMutableDictionary *columnNamesForFileName;
	NSMutableDictionary *indexPathForFileName;
	NSMutableDictionary *searchStringForFileName;

	// Edit view
	IBOutlet EditViewController *editController;
	
	// Search view
    UISearchBar *_searchBar;

	// Toolbars
	IBOutlet UIBarButtonItem *modificationDateButton;
	IBOutlet UIToolbar *detailsViewToolbar;
	IBOutlet UIToolbar *fancyDetailsViewToolbar;
	IBOutlet UIToolbar *htmlDetailsViewToolbar;
	
	// Need to remember this when "Leave CSV Touch"-sheet returns
	UIAlertView *leaveAppView;
	NSURL *leaveAppURL;
	
	// An array with the current indexes to use for the items
	NSMutableArray *importantColumnIndexes;
	int *rawColumnIndexes;
	
	// For use when reading a CSV file list which includes
	// pre-defined columns not to show
	NSMutableDictionary *_preDefinedHiddenColumns;
	
	// Weak reference to the latest shown item
	CSVRow *_latestShownItem;
	
	BOOL searchInputInProgress;
	
	BOOL _showDeletedColumns;
	
	// Ads
	UIView *_contentView;
#if defined(CSV_LITE)
	// Ad support
	ADBannerView *_bannerView;
	BOOL _bannerIsVisible;
#endif
	
}

@property (nonatomic, readonly) UIToolbar *itemsToolbar;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, copy) NSURL *leaveAppURL;
@property (nonatomic, assign) BOOL showDeletedColumns;
@property (nonatomic, retain) UIView *contentView;
#if defined(CSV_LITE)
@property (nonatomic, retain) ADBannerView *bannerView;
@property (nonatomic, assign) BOOL bannerIsVisible;
#endif

+ (CSVDataViewController *) sharedInstance;

- (IBAction) editDone:(id)sender;
- (IBAction) toggleDetailsView:(id)sender;
- (IBAction) nextDetailsClicked:(id)sender;
- (IBAction) previousDetailsClicked:(id)sender;
- (IBAction) toggleShowHideDeletedColumns;

- (void) resetColumnNamesForFile:(CSVFileParser *)file;
- (void) resetColumnNamesForCurrentFile;
- (void) editColumns;

- (void) setFiles:(NSArray *) files;
- (NSArray *) files;

- (void) markFilesAsDirty;
- (void) resortObjects;

- (void) newFileDownloaded:(CSVFileParser *)file;
- (void) removeFileWithName:(NSString *)name;

- (NSArray *) importantColumnIndexes;
- (int *) rawColumnIndexes;

- (void) setHiddenColumns:(NSIndexSet *)hidden forFile:(NSString *)fileName;

- (void) applicationWillTerminate;
- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL) emergencyMode;

- (CSVFileParser *) currentFile;
- (FilesViewController *) fileController;
- (ItemsViewController *) itemController;
- (ParseErrorViewController *) parseErrorController;

// For CSV_TouchAppDelegate
- (NSUInteger) numberOfFiles;
- (BOOL) fileExistsWithURL:(NSString *)URL;

- (void) fileWasSelected:(CSVFileParser *)file;

@end
