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

@interface CSVDataViewController : UINavigationController <UITableViewDelegate>
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
	
	// Weak reference to the latest shown item
	CSVRow *_latestShownItem;
		
	BOOL _showDeletedColumns;	
}

@property (nonatomic, assign) BOOL showDeletedColumns;
@property (nonatomic, retain) ItemsViewController *itemController;

+ (CSVDataViewController *) sharedInstance;

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
