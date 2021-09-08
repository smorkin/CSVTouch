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

@property (nonatomic, weak) CSVFileParser *file;
@property (nonatomic) BOOL needsSort;
@property (nonatomic) BOOL needsResetShortDescriptions; // This will also set the needsSort flag

+ (instancetype) sharedInstance;

// Will reload data in table but also do other necessary stuff to make table udate with current settings
- (void) refresh;

- (IBAction) decreaseTableViewSize;
- (IBAction) increaseTableViewSize;
- (IBAction) toggleItemSortOrder;
- (IBAction)share:(id)sender;

@end

