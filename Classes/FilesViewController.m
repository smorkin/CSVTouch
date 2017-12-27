//
//  FilesViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "FilesViewController.h"
#import "CSVPreferencesController.h"
#import "CSVDataViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "CSVFileParser.h"
#import "FileDownloader.h"

@interface FilesViewController ()

@property (assign) BOOL refreshFilesInProgress;

@end

@implementation FilesViewController

static FilesViewController *_sharedInstance = nil;

+ (instancetype) sharedInstance
{
    return _sharedInstance;
}

- (void) configureToolbarButtons
{
    UIBarButtonItem *refreshAllItems = [[UIBarButtonItem alloc] initWithTitle:@"Refresh all"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(refreshAllFiles)];
    UIBarButtonItem *loadFileListItem = [[UIBarButtonItem alloc] initWithTitle:@"List+"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(loadFileList)];
    
    // Now, add in order:
    NSMutableArray *items = [NSMutableArray array];
    if( [CSVPreferencesController simpleMode])
    {
        [items addObject:[self refreshFilesItem]];
        if([CSVPreferencesController lastUsedListURL])
            [items addObject:refreshAllItems];
    }
    else
    {
        [items addObject:[self refreshFilesItem]];
        [items addObject:refreshAllItems];
        [items addObject:loadFileListItem];
    }
    self.toolbarItems = items;
}

- (void) configureGestures
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //seconds
    [self.tableView addGestureRecognizer:lpgr];
}

- (void) handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if( longPress.state != UIGestureRecognizerStateCancelled)
    {
        // We ignore state and just cancels the gesture
        longPress.enabled = FALSE;
        CGPoint p = [longPress locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath != nil) {
            [self performSegueWithIdentifier:@"ToFileData" sender:[[self objects] objectAtIndex:indexPath.row]];
        }
    }
    else
    {
        longPress.enabled = TRUE;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"ToFileData"])
    {
        [(FileDataViewController *)segue.destinationViewController setFile:sender];
    }
    else if( [segue.identifier isEqualToString:@"ToItems"])
    {
        [(ItemsViewController *)segue.destinationViewController setFile:sender];
    }
}

- (void) configureTable
{
    self.editable = YES;
    self.size = OZY_NORMAL;
}

- (void) configureNavigationBar
{
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self action:@selector(addNewFile)];
    self.navigationItem.rightBarButtonItem = add;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _sharedInstance = self;
    [self configureToolbarButtons];
    [self configureGestures];
    [self configureTable];
    [self configureNavigationBar];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if( [CSVPreferencesController simpleMode])
    {
        self.navigationController.navigationItem.rightBarButtonItem = nil;
        self.editable = NO;
    }    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
}

- (void) refreshAllFiles
{
    [[CSV_TouchAppDelegate sharedInstance] reloadAllFiles];
}

- (void) loadFileList
{
    [[CSV_TouchAppDelegate sharedInstance] loadFileList];
}

- (NSUInteger) indexOfToolbarItemWithSelector:(SEL)selector
{
    NSUInteger index = 0;
    for( UIBarButtonItem *item in self.toolbarItems )
    {
        if( item.action == selector )
            return index;
        index++;
    }
    
    return NSNotFound;
}

- (UIBarButtonItem *) doneItemWithSelector
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(toggleRefreshFiles)];
}

- (UIBarButtonItem *) refreshFilesItem
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Refresh…" style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(toggleRefreshFiles)];
    return button;
}

- (void) toggleRefreshFiles
{
    self.refreshFilesInProgress = !self.refreshFilesInProgress;
    NSUInteger index = [self indexOfToolbarItemWithSelector:@selector(toggleRefreshFiles)];
    
    if( index == NSNotFound )
        return;
    
    if( self.refreshFilesInProgress )
    {
        self.removeDisclosure = YES;
        NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbarItems];
        [items replaceObjectAtIndex:index
                         withObject:[self doneItemWithSelector]];
        self.toolbarItems = items;
    }
    else
    {
        self.removeDisclosure = NO;
        NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbarItems];
        [items replaceObjectAtIndex:index withObject:[self refreshFilesItem]];
        self.toolbarItems = items;
    }
    [self dataLoaded];
}

- (IBAction) addNewFile
{
    [[CSV_TouchAppDelegate sharedInstance] addNewFile];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVFileParser *selectedFile = [[self objects] objectAtIndex:indexPath.row];
    if( self.refreshFilesInProgress && selectedFile)
    {
        [[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:[selectedFile URL]];
    }
    else if( selectedFile)
    {
        if([[CSVDataViewController sharedInstance] fileWasSelected:selectedFile])
        {
            [self performSegueWithIdentifier:@"ToItems" sender:selectedFile];
        }
    }
}

- (void) dataLoaded
{
    self.objects = [CSVFileParser files];
    [super dataLoaded];
}

@end
