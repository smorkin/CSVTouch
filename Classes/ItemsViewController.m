//
//  ItemsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ItemsViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"

#define NORMAL_SORT_ORDER @"▼"
#define REVERSE_SORT_ORDER @"▲"


@interface ItemsViewController ()
{
    CSVFileParser *file;
}
@end

@implementation ItemsViewController

- (void) setFile:(CSVFileParser *)newFile
{
    [file release];
    file = [newFile retain];
}

- (void) configureToolbarButtons
{
    NSMutableArray *items = [NSMutableArray array];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                          target:self
                                                                          action:nil];
    [items addObject:item];
    shrinkItemsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"4lines.png"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(decreaseTableViewSize)];
    [items addObject:shrinkItemsButton];
    enlargeItemsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"2lines.png"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(increaseTableViewSize)];
    [items addObject:enlargeItemsButton];
    sortOrderButton = [[UIBarButtonItem alloc] initWithTitle:NORMAL_SORT_ORDER
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(toggleItemSortOrder)];
    [items addObject:sortOrderButton];
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:nil];
    [items addObject:item];
    itemsCountButton = [[UIBarButtonItem alloc] initWithTitle:@"0"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:nil];
    itemsCountButton.enabled = NO;
    [items addObject:itemsCountButton];
    self.toolbarItems = items;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self configureToolbarButtons];
    [self validateItemSizeButtons];
}

- (void) modifyItemsTableViewSize:(BOOL)increase
{
    if( [CSVPreferencesController modifyItemsTableViewSize:increase] )
    {
        NSArray *a = [[self tableView] indexPathsForVisibleRows];
        NSIndexPath *oldIndexPath = nil;
        if( [a count] > 0 )
            oldIndexPath = [a objectAtIndex:0];
        self.size = [CSVPreferencesController itemsTableViewSize];
        if( oldIndexPath )
            [[self tableView] scrollToRowAtIndexPath:oldIndexPath
                                            atScrollPosition:UITableViewScrollPositionTop
                                                    animated:NO];
    }
}

- (void) validateItemSizeButtons
{
    OzyTableViewSize s = [CSVPreferencesController itemsTableViewSize];
    shrinkItemsButton.enabled = (s == OZY_MINI ? NO : YES);
    enlargeItemsButton.enabled = (s == OZY_NORMAL? NO : YES);
}

- (void) increaseTableViewSize
{
    [self modifyItemsTableViewSize:YES];
    [self validateItemSizeButtons];
}

- (void) decreaseTableViewSize
{
    [self modifyItemsTableViewSize:NO];
    [self validateItemSizeButtons];
}

- (void) toggleItemSortOrder
{
    [CSVPreferencesController toggleReverseItemSorting];
    sortOrderButton.title = [CSVPreferencesController reverseItemSorting] ? REVERSE_SORT_ORDER : NORMAL_SORT_ORDER;
    NSMutableArray *objects = [self objects];
    [objects sortUsingSelector:[CSVRow compareSelector]];
    [self setObjects:objects];
    [self dataLoaded];
}

- (void) updateItemCount
{
    NSString *addString = @"";
    NSUInteger count = [[self objects] count];
    if( count != [[file itemsWithResetShortdescriptions:NO] count] )
        addString = [NSString stringWithFormat:@"/%lu", (unsigned long)[[file itemsWithResetShortdescriptions:NO] count]];
    itemsCountButton.title = [NSString stringWithFormat:@"%lu%@", (unsigned long)count, addString];

}
- (void) setObjects:(NSMutableArray *)objects
{
    [super setObjects:objects];
    [self updateItemCount];
}
@end
