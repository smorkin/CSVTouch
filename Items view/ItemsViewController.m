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

#define MAX_ITEMS_IN_LITE_VERSION 150

#define TO_COLUMNS_EDIT_SEGUE @"ToEdit"
#define TO_DETAILS_SEGUE @"ToDetails"
#define TO_ITEMS_PREFS_SEGUE @"ToItemsViewPrefs"

@interface ItemsViewController ()
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray<CSVRow *> *items;
@property (nonatomic, strong) NSMutableArray *sectionStarts;
@property (nonatomic, strong) NSMutableArray *sectionIndices;
@property CGFloat originalPointsWhenPinchStarted;
@property BOOL hasBeenVisible;
@property NSString *currentSegue;
@property NSString *lastSearchString;
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
            // Now, turns out that if we use section headers, visible rows include those "hidden" under header ->
            // We should actually use a[1] instead of a[0]. Of course, if font for cells is really big/large 1 might not be correct, but it's better than nothing.
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
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
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
    self.clearsSelectionOnViewWillAppear = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    UIPinchGestureRecognizer *p = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.tableView addGestureRecognizer:p];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 32;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self synchUI];
   _sharedInstance = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:YES];
    if( [self.currentSegue isEqualToString:TO_COLUMNS_EDIT_SEGUE])
    {
        [self refresh];
    }
    self.currentSegue = nil;
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

- (void) setFile:(CSVFileParser *)file
{
    _file = file;
    self.needsSort = YES;
    [self updateSearchResultsForSearchController:self.searchController];
    [self setTitle:[self.file defaultTableViewDescription]];
}

- (void) setNeedsResetShortDescriptions:(BOOL)needsResetShortDescriptions
{
    _needsResetShortDescriptions = needsResetShortDescriptions;
    self.needsSort = YES;
}

- (void) showSettings
{
    [self performSegueWithIdentifier:TO_ITEMS_PREFS_SEGUE sender:self];
}

- (void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) openFind
{
// I ought to call self.navigationItem.searchController.active, but if I do becomeFirstResponder won't work, i.e. text field won't be active unless you manually click in it. Weird! See https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    [self.navigationItem.searchController.searchBar becomeFirstResponder];
}

- (void) selectItem:(id)sender
{
    NSInteger itemNumber = [[sender input] integerValue];
    if( [self.items count] > itemNumber)
    {
        NSIndexPath *path = [self indexPathForObjectAtIndex:itemNumber];
        [self.tableView selectRowAtIndexPath:path
                                    animated:NO
                              scrollPosition:NO];
        [self tableView:self.tableView didSelectRowAtIndexPath:path];
    }
}

- (void) addItemShortcuts
{
    UIKeyCommand *cmd;
    if( [self.items count] <= 10 )
    {
        for( int i = 0 ; i < MIN([self.items count], 10); ++i)
        {
            NSString *title = [[self.items objectAtIndex:i] shortDescription];
            if( [title length] > 16)
            {
                title = [NSString stringWithFormat:@"%@...", [title substringToIndex:16]];
            }
            cmd = [UIKeyCommand keyCommandWithInput:[NSString stringWithFormat:@"%d", i]
                                      modifierFlags:UIKeyModifierCommand
                                             action:@selector(selectItem:)
                               discoverabilityTitle:title];
            [self addKeyCommand:cmd];
        }
    }
}

- (void) deleteKeyCommands
{
    NSArray *cmds = [[self keyCommands] copy];
    for( UIKeyCommand *cmd in cmds){
        [self removeKeyCommand:cmd];
    }
}

- (void) addKeyCommands
{
    [self deleteKeyCommands];
    [self addItemShortcuts];
    UIKeyCommand *cmd;
    cmd = [UIKeyCommand keyCommandWithInput:@"b"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(goBack)
                       discoverabilityTitle:@"Go back"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"f"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(openFind)
                       discoverabilityTitle:@"Find"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"+"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(increaseTableViewSize)
                       discoverabilityTitle:@"Zoom in"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"-"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(decreaseTableViewSize)
                       discoverabilityTitle:@"Zoom out"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"t"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(toggleItemSortOrder)
                       discoverabilityTitle:@"Toggle reverse sorting"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@","
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(showSettings)
                       discoverabilityTitle:@"Preferences"];
    [self addKeyCommand:cmd];
}

- (void) sizeChanged
{
    NSArray *a = [[self tableView] indexPathsForVisibleRows];
    NSIndexPath *oldIndexPath = nil;
    if( [a count] > 0 )
    {
        // Here, taking the natural index 0 is actually a bad idea in case we have section headers, because in that case 0 id actually the row underneath the top header (unless the item is the first in the section in which case there is no row under it), but scrolling this to the top later will respect the header. So when repeatedly pinching, we will scroll upwards until we reach the first item in the section which was at the top when pinch started. Hence, use 1 which means we will scroll upwards when zooming in, but as soon as row height >= section header height, "autoscroll" will stop!
        oldIndexPath = [a objectAtIndex: [a count] > 1 ? 1 : 0];
    }
    [self validateItemSizeButtons];
    [self.tableView reloadData];
    if( oldIndexPath )
        [[self tableView] scrollToRowAtIndexPath:oldIndexPath
                                atScrollPosition:UITableViewScrollPositionTop
                                        animated:NO];
}

- (int) getPointsChange:(UIPinchGestureRecognizer *)pinch
{
    CGFloat currentPoints = [CSVPreferencesController itemsListFontSize];
    CGFloat scaledPoints = pinch.scale * self.originalPointsWhenPinchStarted;
    return (scaledPoints - currentPoints);
}

- (void) applyPointsChange:(int)pointsChange
{
    if( pointsChange == 0 )
        return;
    
    [CSVPreferencesController changeItemsListFontSize:pointsChange];
    [self sizeChanged];
}

- (void) pinch:(UIPinchGestureRecognizer *)pinch
{
    switch(pinch.state)
    {
        case UIGestureRecognizerStateBegan:
            self.originalPointsWhenPinchStarted = [CSVPreferencesController itemsListFontSize];
            // Intentional fallthrough!
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self applyPointsChange:[self getPointsChange:pinch]];
            break;
        default:
            break;
    }
}

- (void) modifyItemsTableViewSize:(BOOL)increase
{
    (increase ? [CSVPreferencesController increaseItemsListFontSize] : [CSVPreferencesController decreaseItemsListFontSize]);
    [self sizeChanged];
}

- (void) validateItemSizeButtons
{
    shrinkItemsButton.enabled = [CSVPreferencesController canDecreaseItemsListFontSize];
    enlargeItemsButton.enabled = [CSVPreferencesController canIncreaseItemsListFontSize];
}

- (void) synchUI
{
    sortOrderButton.image = [CSVPreferencesController reverseItemSorting] ?
    [UIImage imageNamed:@"descending"] : [UIImage imageNamed:@"ascending"];
}

- (IBAction)share:(id)sender
{
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[[self.view pdfData]] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.permittedArrowDirections =
    UIPopoverArrowDirectionAny;
    controller.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction) increaseTableViewSize
{
    [self modifyItemsTableViewSize:YES];
}

- (IBAction) decreaseTableViewSize
{
    [self modifyItemsTableViewSize:NO];
}

- (IBAction) toggleItemSortOrder
{
    [CSVPreferencesController toggleReverseItemSorting];
    [self synchUI];
    self.needsSort = YES;
    [self refresh];
}

- (void) updateItemCount
{
    NSString *addString = @"";
    NSUInteger count = [self.items count];
    if( count != [self.file.parsedItems count] )
        addString = [NSString stringWithFormat:@"/%lu", (unsigned long)[self.file.parsedItems count]];
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

- (NSIndexPath *) indexPathForObjectAtIndex:(NSUInteger)index
{
    if( index >= [self.items count] || index == NSNotFound )
        return [NSIndexPath indexPathForRow:0 inSection:0];
    
    if( [self.sectionStarts count] > 0 )
    {
        NSUInteger section;
        for( section = 1 ; section < [self.sectionStarts count] ; section++ )
        {
            if( index < [[self.sectionStarts objectAtIndex:section] intValue] )
                return [NSIndexPath indexPathForRow:(index - [[self.sectionStarts objectAtIndex:section-1] intValue] ) inSection:section-1];
        }
        return [NSIndexPath indexPathForRow:(index - [[self.sectionStarts objectAtIndex:section-1] intValue] ) inSection:section-1];
    }
    else
    {
        return [NSIndexPath indexPathForRow:index inSection:0];
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
    if( self.needsResetShortDescriptions)
    {
        [self.file invalidateShortDescriptions];
        self.file.isSorted = NO;
        self.needsResetShortDescriptions = NO;
    }
    if( self.needsSort)
    {
        if( [CSVPreferencesController shouldSort])
        {
            [self.items sortUsingSelector:[CSVRow compareSelector]];
            self.file.isSorted = YES;
        }
        else if(self.file.isSorted)
        {
            // In case in the future settings will be accessbile while search is active, we need to fix something here since we will show all items after the code below
            // Also, lazy code. Instead I could keep the original order of all rows somewher eand use that, but hey, this works and it is not too slow. Also, I suspect changing whether to sort or not will be very uncommon
            [self.file reparseIfParsed];
            self.items = self.file.parsedItems;
            self.file.isSorted = NO;
        }
        self.needsSort = NO;
    }
    [self refreshIndices];
    [self.tableView reloadData];
    [self addKeyCommands];
}

- (void) setItems:(NSMutableArray *)items
{
    if( [CSVPreferencesController restrictedDataVersionRunning] && [items count] > MAX_ITEMS_IN_LITE_VERSION )
    {
        [items removeObjectsInRange:NSMakeRange(MAX_ITEMS_IN_LITE_VERSION, [items count] - MAX_ITEMS_IN_LITE_VERSION)];
    }
    
    _items = items;
    [self updateItemCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( [self.sectionStarts count] > 0 )
    {
        if( section == [self.sectionStarts count] - 1 )
            return [self.items count] - [[self.sectionStarts lastObject] intValue];
        else
            return [[self.sectionStarts objectAtIndex:section+1] intValue] - [[self.sectionStarts objectAtIndex:section] intValue];
    }
    else
    {
        return [self.items count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if( [self.sectionStarts count] > 0 )
    {
        return [self.sectionStarts count];
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
    if( [CSVPreferencesController useMonospacedFont])
        [cell.label setFont:[UIFont fontWithName:@"Menlo" size:[CSVPreferencesController itemsListFontSize]]];
    else
        [cell.label setFont:[UIFont systemFontOfSize:[CSVPreferencesController itemsListFontSize]]];

    CSVRow *item;
    if( [self.sectionStarts count] > 0 )
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

- (void) smartSearchReset:(CSVRow *)selectedRow
{
    self.searchController.searchBar.text = @"";
    self.searchController.active = NO;
    // Table view has now been reset so we select clicked item + scroll it to top
    NSIndexPath *path = [self indexPathForObjectAtIndex:[self.items indexOfObject:selectedRow]];
    [self.tableView selectRowAtIndexPath:path
                                animated:NO
                          scrollPosition:UITableViewScrollPositionTop];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVRow *row = [self.items objectAtIndex:[self indexForObjectAtIndexPath:indexPath]];
    [self performSegueWithIdentifier:@"ToDetails" sender:row];
    // If we are searching and have smart search clearing on, we should stop search etc,
    if( [CSVPreferencesController smartSeachClearing] &&
       self.searchController.active &&
       ![self.searchController.searchBar.text isEqualToString:@""])
    {
        [self smartSearchReset:row];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:TO_COLUMNS_EDIT_SEGUE]){
        [(EditFileColumnsController *)segue.destinationViewController setFile:self.file];
        self.currentSegue = TO_COLUMNS_EDIT_SEGUE;
    }
    else if([segue.identifier isEqualToString:TO_DETAILS_SEGUE])
    {
        DetailsPagesController *dpc = segue.destinationViewController;
        [dpc setItems:self.items];
        dpc.initialIndex = [self.items indexOfObject:sender];
        self.currentSegue = TO_DETAILS_SEGUE;
    }
    else if([segue.identifier isEqualToString:@"ToItemsViewPrefs"])
    {
        segue.destinationViewController.popoverPresentationController.delegate = self;
        self.currentSegue = TO_ITEMS_PREFS_SEGUE;
    }
}
@end

@implementation ItemsViewController (Search)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Search ignores spaces before/after text. Also, in case the search string has not changed we don't want to go through the code since it will mean selection disappears (this matters when we have a search string, click on row, show details, and then go back -> this code is called again when view appears, and selection disappears).
    NSString *searchString = [searchController.searchBar.text lowercaseString];
    searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    if( [searchString isEqualToString:self.lastSearchString])
    {
        return;
    }
    // Now, check if there is a quoted string, i.e. search is of the form
    // "<some string>"
    // If so, we'll do a seaerch for <some string>; if not, we search for objects containing all the words in search string
    NSString *quotedSearchWord = nil;
    if( [searchString length] >= 2 &&
       (([searchString hasPrefix:@"”"] && [searchString hasSuffix:@"”"]) ||
       ([searchString hasPrefix:@"\""] && [searchString hasSuffix:@"\""])))
    {
        quotedSearchWord = [searchString substringWithRange:NSMakeRange(1, [searchString length] - 2)];
    }
    
    // Now we check if there is something to search for at all
    if( searchString && ![searchString isEqualToString:@""] &&
       (!quotedSearchWord || ![quotedSearchWord isEqualToString:@""]))
    {
        NSMutableArray *filteredRows = [NSMutableArray array];
        NSArray *words = (quotedSearchWord ? [NSArray arrayWithObject:quotedSearchWord] : [searchString componentsSeparatedByString:@" "]);
        NSUInteger wordCount = [words count];
        NSUInteger wordNr;
        NSString *objectDescription;
        // In case old searchstring is a substring of new -> we only need to look among items currently shown
        BOOL useCurrentItems = self.lastSearchString &&
        ![self.lastSearchString isEqualToString:@""] &&
        [searchString hasSubstring:self.lastSearchString];
        for( CSVRow *row in (useCurrentItems ? self.items : self.file.parsedItems) )
        {
            objectDescription = [row lowercaseShortDescription];
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
        self.items = self.file.parsedItems;
    }
    [self refresh];
    [self addKeyCommands];
    [self.tableView scrollToTopWithAnimation:NO];
    self.lastSearchString = searchString;
}

@end

@implementation ItemsViewController (PopoverDelegate)
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}
@end
