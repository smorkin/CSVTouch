//
//  ItemsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ItemsViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "CSVDataViewController.h"

#define NORMAL_SORT_ORDER @"↓"
#define REVERSE_SORT_ORDER @"↑"


@interface ItemsViewController ()
@property (nonatomic, weak) CSVFileParser *file;
@end

@implementation ItemsViewController

- (void) updateDateButton
{
    NSString *date;
    NSString *time;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    date = [dateFormatter stringFromDate:self.file.downloadDate];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    time = [dateFormatter stringFromDate:self.file.downloadDate];
    
    [modificationDateButton.customView setText:[NSString stringWithFormat:@"%@\n%@",
                                                                date, time]];
}

- (void) configureTable
{
    self.editable = NO;
    self.size = [CSVPreferencesController itemsTableViewSize];
    self.useIndexes = [CSVPreferencesController useGroupingForItems];
    self.groupNumbers = [CSVPreferencesController groupNumbers];
    self.useFixedWidth = [CSVPreferencesController useFixedWidth];
}

- (void) configureDateButton
{
    CGRect frame = CGRectMake(0, 0, 72, 44);
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.font = [UIFont fontWithName:l.font.fontName size:10];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor blackColor];
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 2;
    modificationDateButton.customView = l;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self configureTable];
    [self validateItemSizeButtons];
    [self configureDateButton];
    [CSVDataViewController sharedInstance].itemController = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Might be that setObjects is called before setFile -> we need to update counts
    [self updateItemCount];
    [self updateDateButton];
    self.navigationController.toolbarHidden = NO;
    [self dataLoaded];
    [super viewWillAppear:animated];
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

- (IBAction) increaseTableViewSize
{
    [self modifyItemsTableViewSize:YES];
    [self validateItemSizeButtons];
}

- (IBAction) decreaseTableViewSize
{
    [self modifyItemsTableViewSize:NO];
    [self validateItemSizeButtons];
}

- (IBAction) toggleItemSortOrder
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
    if( count != [[self.file itemsWithResetShortdescriptions:NO] count] )
        addString = [NSString stringWithFormat:@"/%lu", (unsigned long)[[self.file itemsWithResetShortdescriptions:NO] count]];
    itemsCountButton.title = [NSString stringWithFormat:@"%lu%@", (unsigned long)count, addString];

}
- (void) setObjects:(NSMutableArray *)objects
{
    [super setObjects:objects];
    [self updateItemCount];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[CSVDataViewController sharedInstance] selectedItemAtIndexPath:indexPath];
}

- (void) dataLoaded
{
    self.objects = [self.file itemsWithResetShortdescriptions:NO];
    [super dataLoaded];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"ToEdit"]){
        [(EditViewController *)segue.destinationViewController setFile:self.file];
    }
}

@end
