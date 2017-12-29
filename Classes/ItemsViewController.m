//
//  ItemsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ItemsViewController.h"
#import "DetailsViewController.h"
#import "EditViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "OzymandiasAdditions.h"

#define NORMAL_SORT_ORDER @"↓"
#define REVERSE_SORT_ORDER @"↑"
#define MAX_ITEMS_IN_LITE_VERSION 150


@interface ItemsViewController ()
@property (nonatomic, weak) CSVFileParser *file;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) BOOL shouldAutoscroll;
@end

@implementation ItemsViewController

static NSMutableDictionary *_indexPathForFileName;

+ (void) initialize
{
    _indexPathForFileName = [NSMutableDictionary dictionary];
}

- (void) cacheCurrentScrollPosition
{
    if( self.file && [self.file fileName] )
    {
        NSArray<NSIndexPath *> *a = [self.tableView indexPathsForVisibleRows];
        if( [a count] > 0 ){
            // Now, turns out that if we use section headers, visible rows include those under header ->
            // We should actually use a[1] instead of a[0]
            NSUInteger i = 0;
            if( self.useIndexes && [a count] > 1 ){
                i = 1;
            }
            [_indexPathForFileName setObject:[[a objectAtIndex:i] dictionaryRepresentation] forKey:[self.file fileName]];
        }
        else
            [_indexPathForFileName removeObjectForKey:[self.file fileName]];
    }
}

- (void) updateInitialScrollPosition
{
    [self.tableView scrollToTopWithAnimation:NO];
    NSDictionary *indexPathDictionary = [_indexPathForFileName objectForKey:[self.file fileName]];
    if( [indexPathDictionary isKindOfClass:[NSDictionary class]] )
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathWithDictionary:indexPathDictionary];
        if( [self itemExistsAtIndexPath:indexPath] )
        {
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }
    }
    // And remove the cache since we have now used it
    [_indexPathForFileName removeObjectForKey:[self.file fileName]];
}

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

- (void) configureSearch
{
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search items";
    self.navigationItem.searchController = self.searchController;
    self.definesPresentationContext = YES;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self configureTable];
    [self validateItemSizeButtons];
    [self configureDateButton];
    [self configureSearch];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) viewWillAppear:(BOOL)animated
{
    // Might be that setObjects is called before setFile -> we need to update counts
    [self updateItemCount];
    [self updateDateButton];
    [self resetObjects];
    [self dataLoaded];
    [self setTitle:[self.file defaultTableViewDescription]];
    self.navigationController.toolbarHidden = NO;
    self.shouldAutoscroll = YES;
    [super viewWillAppear:animated];
}

// http://www.yichizhang.info/2015/03/02/prescroll-a-uitableview.html
- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if( self.shouldAutoscroll){
        [self updateInitialScrollPosition];
        self.shouldAutoscroll = NO;
    }
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self cacheCurrentScrollPosition];
    [super viewWillDisappear:animated];
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

- (void) resetObjects
{
    NSMutableArray *rows = [self.file itemsWithResetShortdescriptions:NO];
    [rows sortUsingSelector:[CSVRow compareSelector]];
    self.objects = rows;
}

- (void) setObjects:(NSMutableArray *)objects
{
    if( [CSVPreferencesController restrictedDataVersionRunning] && [objects count] > MAX_ITEMS_IN_LITE_VERSION )
    {
        [objects removeObjectsInRange:NSMakeRange(MAX_ITEMS_IN_LITE_VERSION, [objects count] - MAX_ITEMS_IN_LITE_VERSION)];
    }
    
    [super setObjects:objects];
    [self updateItemCount];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVRow *row = [[self objects] objectAtIndex:[self indexForObjectAtIndexPath:indexPath]];
    [self performSegueWithIdentifier:@"ToDetails" sender:row];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"ToEdit"]){
        [(EditViewController *)segue.destinationViewController setFile:self.file];
    }
    else if([segue.identifier isEqualToString:@"ToDetails"])
    {
        [(DetailsViewController *)segue.destinationViewController setRow:sender];
    }
}

@end

@implementation ItemsViewController (Search)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [searchController.searchBar.text lowercaseString];
    NSMutableArray *allRows = [self.file itemsWithResetShortdescriptions:NO];

    if( searchString && ![searchString isEqualToString:@""] )
    {
        NSMutableArray *filteredRows = [NSMutableArray array];
        NSArray *words = [searchString componentsSeparatedByString:@" "];
        NSUInteger wordCount = [words count];
        NSUInteger wordNr;
        NSString *objectDescription;
        for( CSVRow *row in allRows )
        {
            objectDescription = [[row shortDescription] lowercaseString];
            for( wordNr = 0 ;
                wordNr < wordCount && [objectDescription hasSubstring:[words objectAtIndex:wordNr]];
                wordNr++ );
            if( wordNr == wordCount )
                [filteredRows addObject:row];
        }
        self.objects = filteredRows;
    }
    else
    {
        self.objects = allRows;
    }
    [self dataLoaded];
}

@end

