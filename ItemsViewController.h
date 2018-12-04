//
//  ItemsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import <UIKit/UIKit.h>
#import "CSVFileParser.h"

@interface ItemsViewController : UITableViewController
{
    // Toolbar
    IBOutlet UIBarButtonItem *shrinkItemsButton;
    IBOutlet UIBarButtonItem *enlargeItemsButton;
    IBOutlet UIBarButtonItem *sortOrderButton;
    IBOutlet UIBarButtonItem *itemsCountButton;
}

+ (instancetype) sharedInstance;

// Will reload data in table but also do other necessary stuff to make table udate with current settings
- (void) refresh;

// Will force a reparsing of the file, typically if some fundamtental setting has changed which requires this.
- (void) reparseFile;

- (void) setFile:(CSVFileParser *)file;

- (IBAction) decreaseTableViewSize;
- (IBAction) increaseTableViewSize;
- (IBAction) toggleItemSortOrder;

@end

