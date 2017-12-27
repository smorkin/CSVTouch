//
//  ItemsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "OzyTableViewController.h"
#import "CSVFileParser.h"

@interface ItemsViewController : OzyTableViewController
{
    // Toolbar
    IBOutlet UIBarButtonItem *shrinkItemsButton;
    IBOutlet UIBarButtonItem *enlargeItemsButton;
    IBOutlet UIBarButtonItem *sortOrderButton;
    IBOutlet UIBarButtonItem *itemsCountButton;
    IBOutlet UIBarButtonItem *modificationDateButton;
}

- (void) setFile:(CSVFileParser *)file;

- (IBAction) decreaseTableViewSize;
- (IBAction) increaseTableViewSize;
- (IBAction) toggleItemSortOrder;

@end

@interface ItemsViewController (Search) <UISearchResultsUpdating>
@end
