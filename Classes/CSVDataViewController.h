//
//  CSVDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ParseErrorViewController.h"
#import "ItemsViewController.h"
#import "EditViewController.h"
#import "FancyDetailsController.h"

@class OzyTableViewController,
CSVFileParser, 
CSVRow,
OzyTextViewController,
OzyWebViewController;

@interface CSVDataViewController : UINavigationController <UITableViewDelegate, UISearchBarDelegate>
{
	IBOutlet OzyTextViewController *detailsController;
	IBOutlet FancyDetailsController *fancyDetailsController;
	IBOutlet OzyWebViewController *htmlDetailsController;
	IBOutlet ParseErrorViewController *parseErrorController;

	int selectedDetailsView; // 0 = fancy, 1 = web, 2 = simple
	
	BOOL itemsNeedResorting;
	BOOL itemsNeedFiltering;

    CSVFileParser *currentFile;

	// Cached data for files
	NSMutableDictionary *indexPathForFileName;
	NSMutableDictionary *searchStringForFileName;
	
	// Search view
    UISearchBar *_searchBar;

	// Weak reference to the latest shown item
	CSVRow *_latestShownItem;
	
	BOOL searchInputInProgress;
	
	BOOL _showDeletedColumns;	
}

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL showDeletedColumns;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) ItemsViewController *itemController;

+ (CSVDataViewController *) sharedInstance;

- (void) editDone:(id)sender;

- (void) resortObjects;

- (void) applicationWillTerminate;
- (void) applicationDidFinishLaunchingInEmergencyMode:(BOOL) emergencyMode;

- (CSVFileParser *) currentFile;
- (ItemsViewController *) itemController;
- (ParseErrorViewController *) parseErrorController;

- (void) selectedItemAtIndexPath:(NSIndexPath *)indexPath;

- (void) gotoNextDetailsView;

// Returns TRUE if everything OK
- (BOOL) fileWasSelected:(CSVFileParser *)file;

@end
