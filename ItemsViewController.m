//
//  ItemsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ItemsViewController.h"
#import "DetailsViewController.h"
#import "EditFileColumnsController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "OzymandiasAdditions.h"
#import "DetailsPagesController.h"
#include "AutoSizingTableViewCell.h"

#define NORMAL_SORT_ORDER @"↓"
#define REVERSE_SORT_ORDER @"↑"
#define MAX_ITEMS_IN_LITE_VERSION 150


@interface ItemsViewController ()
@property (nonatomic, weak) CSVFileParser *file;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray<CSVRow *> *items;
@property (nonatomic, strong) NSMutableArray *sectionStarts;
@property (nonatomic, strong) NSMutableArray *sectionIndices;
@property BOOL hasBeenVisible;
@end

@interface ItemsViewController (PopoverDelegate) <UIPopoverPresentationControllerDelegate>
@end

@interface ItemsViewController (Search) <UISearchResultsUpdating>
@end


@implementation ItemsViewController

static ItemsViewController *_sharedInstance = nil;

+ (instancetype) sharedInstance
{
    return _sharedInstance;
}

static NSMutableDictionary *_indexPathForFileName;

+ (void) initialize
{
    _indexPathForFileName = [NSMutableDictionary dictionary];
}

- (void) cacheCurrentScrollPosition
{
    [_indexPathForFileName removeObjectForKey:[self.file fileName]];
    if( self.file && [self.file fileName] )
    {
        // Bug sometimes trigged in indexPathsForVisibleRows, unless visibleCells is called first:
        // https://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
        [self.tableView visibleCells];
        NSArray<NSIndexPath *> *a = [self.tableView indexPathsForVisibleRows];
        if( [a count] > 0 ){
            // Now, turns out that if we use section headers, visible rows include those under header ->
            // We should actually use a[1] instead of a[0].
            NSUInteger i = 0;
            if( [CSVPreferencesController useGroupingForItems] && [a count] > 1 )
            {
                i = 1;
            }
            [_indexPathForFileName setObject:[a objectAtIndex:i] forKey:[self.file fileName]];
        }
    }
}

- (BOOL) itemExistsAtIndexPath:(NSIndexPath *)indexPath
{
    if( [self.sectionStarts count] > 0 )
    {
        if( indexPath.section == [self.sectionStarts count] - 1 )
            return [[self.sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row < [self.items count];
        else if( indexPath.section < [self.sectionStarts count] - 1 )
            return [[self.sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row <
            [[self.sectionStarts objectAtIndex:indexPath.section + 1] intValue];
        else
            return NO;
    }
    else if( indexPath.section != 0 )
    {
        return NO;
    }
    else
    {
        return indexPath.row < [self.items count];
    }
}

- (NSIndexPath *)cachedIndexPathPosition
{
    NSIndexPath *indexPath = [_indexPathForFileName objectForKey:[self.file fileName]];
    if( [indexPath isKindOfClass:[NSIndexPath class]] )
    {
        return indexPath;
    }
    return nil;
}

- (void) updateInitialScrollPosition
{
    [self.tableView scrollToTopWithAnimation:NO];
    NSIndexPath *indexPath = [self cachedIndexPathPosition];
    if( [self itemExistsAtIndexPath:indexPath] )
    {
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
}

- (void) configureTable
{
    [self.tableView registerNib:[UINib nibWithNibName:@"AutoSizingTableViewCell" bundle:nil] forCellReuseIdentifier:@"AutoCell"];
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

- (BOOL) isTopItem:(NSIndexPath *)path
{
    if( !path){
        // A bit weird, but conceptually no path kind of is the same as the top path
        return YES;
    }
    if([CSVPreferencesController useGroupingForItems])
        return (path.section == 1 && path.row == 1);
    else
        return (path.section == 0 && path.row == 0);
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self configureTable];
    [self validateItemSizeButtons];
    [self configureSearch];
    self.items = [NSMutableArray array];
    self.sectionStarts = [NSMutableArray array];
    self.sectionIndices = [NSMutableArray array];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _sharedInstance = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self updateItemCount];
    [self.file sortItems]; // Need to sort rows before we set objects since otherwise indexes will be messed up
    [self updateSearchResultsForSearchController:self.searchController]; // To keep search results we update objects by going through search controller
    [self setTitle:[self.file defaultTableViewDescription]];
    self.navigationController.toolbarHidden = NO;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 32;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [super viewWillAppear:animated];
}

// http://www.yichizhang.info/2015/03/02/prescroll-a-uitableview.html
- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if( !self.hasBeenVisible){
        [self updateInitialScrollPosition];
        self.hasBeenVisible = YES;
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self cacheCurrentScrollPosition];
    [super viewWillDisappear:animated];
}

- (void) modifyItemsTableViewSize:(BOOL)increase
{
    (increase ? [CSVPreferencesController increaseItemsListFontSize] : [CSVPreferencesController decreaseItemsListFontSize]);
    NSArray *a = [[self tableView] indexPathsForVisibleRows];
    NSIndexPath *oldIndexPath = nil;
    if( [a count] > 0 )
        oldIndexPath = [a objectAtIndex:0];
    if( oldIndexPath )
        [[self tableView] scrollToRowAtIndexPath:oldIndexPath
                                atScrollPosition:UITableViewScrollPositionTop
                                        animated:NO];
}

- (void) validateItemSizeButtons
{
    shrinkItemsButton.enabled = [CSVPreferencesController canDecreaseItemsListFontSize];
    enlargeItemsButton.enabled = [CSVPreferencesController canIncreaseItemsListFontSize];
}

- (IBAction) increaseTableViewSize
{
    [self modifyItemsTableViewSize:YES];
    [self validateItemSizeButtons];
    [self.tableView reloadData];
}

- (IBAction) decreaseTableViewSize
{
    [self modifyItemsTableViewSize:NO];
    [self validateItemSizeButtons];
    [self.tableView reloadData];
}

- (IBAction) toggleItemSortOrder
{
    [CSVPreferencesController toggleReverseItemSorting];
    sortOrderButton.title = [CSVPreferencesController reverseItemSorting] ? REVERSE_SORT_ORDER : NORMAL_SORT_ORDER;
    [self.items sortUsingSelector:[CSVRow compareSelector]];
    // In case we have a subset of the file, let's sort the file as well
    if( self.items != [self.file itemsWithResetShortdescriptions:NO])
    {
        [self.file sortItems];
    }
    [self.tableView reloadData];
}

- (void) updateItemCount
{
    NSString *addString = @"";
    NSUInteger count = [self.items count];
    if( count != [[self.file itemsWithResetShortdescriptions:NO] count] )
        addString = [NSString stringWithFormat:@"/%lu", (unsigned long)[[self.file itemsWithResetShortdescriptions:NO] count]];
    itemsCountButton.title = [NSString stringWithFormat:@"%lu%@", (unsigned long)count, addString];

}

- (NSUInteger) indexForObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if( [self.sectionStarts count] > 0 )
    {
        if( indexPath.section < [self.sectionStarts count] )
            return [[self.sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row;
        else
            return NSNotFound;
    }
    else
    {
        return indexPath.row;
    }
}

- (NSString *) comparisonCharacterForCharacter:(NSString *)character
{
    if( [CSVPreferencesController groupNumbers] && [character containsDigit] )
        return @"0";
    else if( (sortingMask & NSCaseInsensitiveSearch) == 0 )
        return character;
    else
        return [character lowercaseString];
}

- (NSString *) sectionTitleForCharacter:(NSString *)character
{
    if( [CSVPreferencesController groupNumbers] && [character containsDigit] )
        return @"0-9";
    else if( (sortingMask & NSCaseInsensitiveSearch) == 0 )
        return character;
    else
        return [character uppercaseString];
}

- (void) refreshIndices
{
    [self.sectionStarts removeAllObjects];
    [self.sectionIndices removeAllObjects];
    if( [CSVPreferencesController useGroupingForItems] )
    {
        [self.sectionStarts addObject:[NSNumber numberWithInt:0]];
        [self.sectionIndices addObject:UITableViewIndexSearch];
        
        NSUInteger objectCount = [self.items count];
        NSString *latestFirstLetter = nil;
        NSString *currentFirstLetter;
        for( NSUInteger i = 0 ; i < objectCount ; i++)
        {
            NSString *shortDescription = [[self.items objectAtIndex:i] shortDescription];
            if( [shortDescription length] == 0 )
                continue;
            
            // For performance reasons, we compare using isEqualToString: before we
            // do the possible transformation to comparison character
            currentFirstLetter = [shortDescription substringToIndex:1];
            if(!latestFirstLetter ||
               (![currentFirstLetter isEqualToString:latestFirstLetter] &&
                ![[self comparisonCharacterForCharacter:currentFirstLetter] isEqualToString:
                  [self comparisonCharacterForCharacter:latestFirstLetter]] ))
            {
                [self.sectionStarts addObject:[NSNumber numberWithUnsignedInteger:i]];
                [self.sectionIndices addObject:[self sectionTitleForCharacter:currentFirstLetter]];
                latestFirstLetter = currentFirstLetter;
            }
        }
    }
}

- (void) refresh
{
    [self.file itemsWithResetShortdescriptions:YES]; // Call to reset
    [self.file sortItems];
    [self refreshIndices];
    [self.tableView reloadData];
}

- (void) setItems:(NSMutableArray *)items
{
    if( [CSVPreferencesController restrictedDataVersionRunning] && [items count] > MAX_ITEMS_IN_LITE_VERSION )
    {
        [items removeObjectsInRange:NSMakeRange(MAX_ITEMS_IN_LITE_VERSION, [items count] - MAX_ITEMS_IN_LITE_VERSION)];
    }
    
    _items = items;
    [self updateItemCount];
    [self refresh];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( [_sectionStarts count] > 0 )
    {
        if( section == [_sectionStarts count] - 1 )
            return [self.items count] - [[self.sectionStarts objectAtIndex:section] intValue];
        else
            return [[_sectionStarts objectAtIndex:section+1] intValue] - [[_sectionStarts objectAtIndex:section] intValue];
    }
    else
    {
        return [self.items count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if( [_sectionStarts count] > 0 )
    {
        return [_sectionStarts count];
    }
    else
    {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( [self.sectionIndices count] > 0 )
    {
        if ( section == 0 )
            return nil;
        return [self.sectionIndices objectAtIndex:section];
    }
    else
    {
        return @"";
    }
    
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if( [self.sectionIndices count] > 0 )
    {
        return self.sectionIndices;
    }
    else
    {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index
{
    if( [self.sectionIndices count] > 0 )
    {
        if (index == 0)
        {
            if( self.navigationItem.searchController ){
                self.navigationItem.searchController.active = YES;
                [self.navigationItem.searchController becomeFirstResponder];
            }
        }
        return [self.sectionIndices indexOfObject:title];
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AutoSizingTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"AutoCell" forIndexPath:indexPath];
    if( [CSVPreferencesController useFixedWidth])
        [cell.label setFont:[UIFont fontWithName:@"Courier-Bold" size:[CSVPreferencesController itemsListFontSize]]];
    else
        [cell.label setFont:[UIFont systemFontOfSize:[CSVPreferencesController itemsListFontSize]]];

    CSVRow *item;
    if( [_sectionStarts count] > 0 )
        item = [self.items objectAtIndex:[[self.sectionStarts objectAtIndex:indexPath.section] intValue] + indexPath.row];
    else
        item = [self.items objectAtIndex:indexPath.row];
    cell.label.text = [item tableViewDescription];
    cell.label.numberOfLines = [CSVPreferencesController multilineItemCells] ? 0 : 1;
    cell.accessoryType = ([CSVPreferencesController useGroupingForItems] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator);
    if( self.file.iconIndex != NSNotFound )
    {
        cell.imageWidthConstraint.constant = 32;
        cell.imageHeightConstraint.constant =32;
        cell.imageWTrailingSpaceConstraint.constant = 8;
        UIImage *image = nil;
        NSString *imageName = [item imageName];
        if( !imageName)
        {
            imageName = [item emptyImageName];
        }
        if( imageName){
            image = [UIImage imageNamed:[item imageName]];
        }
        cell.view.image = image;
    }
    else
    {
        cell.view.image = nil;
        cell.imageWidthConstraint.constant = 0;
        cell.imageHeightConstraint.constant = 0;
        cell.imageWTrailingSpaceConstraint.constant = 0;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVRow *row = [self.items objectAtIndex:[self indexForObjectAtIndexPath:indexPath]];
    [self performSegueWithIdentifier:@"ToDetails" sender:row];
    if( [CSVPreferencesController smartSeachClearing]){
        self.searchController.searchBar.text = @"";
        self.searchController.active = NO;
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"ToEdit"]){
        [(EditFileColumnsController *)segue.destinationViewController setFile:self.file];
    }
    else if([segue.identifier isEqualToString:@"ToDetails"])
    {
        DetailsPagesController *dpc = segue.destinationViewController;
        [dpc setItems:self.items];
        dpc.initialIndex = [self.items indexOfObject:sender];
    }
    else if([segue.identifier isEqualToString:@"ToItemsViewPrefs"])
    {
        segue.destinationViewController.popoverPresentationController.delegate = self;
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
        self.items = filteredRows;
    }
    else
    {
        self.items = allRows;
    }
    [self.tableView reloadData];
}

@end

@implementation ItemsViewController (PopoverDelegate)
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}
@end
