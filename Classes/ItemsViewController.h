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
    UIBarButtonItem *shrinkItemsButton;
    UIBarButtonItem *enlargeItemsButton;
    UIBarButtonItem *sortOrderButton;
    UIBarButtonItem *itemsCountButton;
}

- (void) setFile:(CSVFileParser *)file;

@end
