//
//  FilesViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "FilesViewController.h"
#import "CSVPreferencesController.h"
#import "CSV_TouchAppDelegate.h"
#import "CSVFileParser.h"
#import "ItemsViewController.h"
#import "ParseErrorViewController.h"
#import "AddFilesSelectionController.h"

@interface FilesViewController ()
@property BOOL UIDisabled;
@end

@implementation FilesViewController

static FilesViewController *_sharedInstance = nil;

+ (instancetype) sharedInstance
{
    return _sharedInstance;
}

- (void) configureGestures
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.35; //seconds
    [self.tableView addGestureRecognizer:lpgr];
}

- (void) handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if( longPress.state != UIGestureRecognizerStateCancelled)
    {
        // We ignore state and just cancels the gesture
        longPress.enabled = FALSE;
        if( self.UIDisabled )
        {
            return;
        }
        CGPoint p = [longPress locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath != nil) {
            [self performSegueWithIdentifier:@"ToFileData" sender:[[CSVFileParser files] objectAtIndex:indexPath.row]];
            // For some reason table view is in wonky mode with selection here: The row is selected, but when returning to this view it is still selected, and clicking a new row will not select that one. So if you look at file data for a file, go back to file list, and simply click on new file, you will see items from the file for which you looked at its data instead of the actually clicked one. Hence, the following code which fixes this.
            // The delay is just to not make the row visually deselect before you see the file data.
            [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:1];
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
    else if( [segue.identifier isEqualToString:@"ToParseError"])
    {
        [(ParseErrorViewController *)segue.destinationViewController setErrorText:[(CSVFileParser *)sender parseErrorString]];
    }
    else if( [segue.identifier isEqualToString:@"ToAddFiles"]){
        segue.destinationViewController.popoverPresentationController.delegate = self;
        AddFilesSelectionController *controller = segue.destinationViewController;
        [controller.tableView layoutIfNeeded];
        CGSize s = [controller.tableView contentSize];
        s.width = MIN(s.width, 300);
        controller.preferredContentSize = s;
    }
    else if( [segue.identifier isEqualToString:@"ToFilesPrefs"])
    {
        segue.destinationViewController.popoverPresentationController.delegate = self;
    }
}

// To avoid full screen presentation
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (void) addFileUsingURL
{
    [CSVFileParser clearAllDownloadFlags];
    [[CSV_TouchAppDelegate sharedInstance] loadNewFile];
}

- (void) addFileUsingURLList
{
    [CSVFileParser clearAllDownloadFlags];
    [[CSV_TouchAppDelegate sharedInstance] loadFileList];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls
{
    [[CSV_TouchAppDelegate sharedInstance] readLocalFiles:urls];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
}

- (void)importLocalFile
{
    NSMutableArray *types = [NSMutableArray array];
    [types addObject:@"public.comma-separated-values-text"];
    [types addObject:@"public.text"];
    [types addObject:@"public.plain-text"];
    
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    documentPicker.allowsMultipleSelection = YES;
    [self presentViewController:documentPicker animated:YES completion:nil];    
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _sharedInstance = self;
    [self configureGestures];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.clearsSelectionOnViewWillAppear = YES;
    self.UIDisabled = NO;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.refreshControl addTarget:self
                            action:@selector(refreshAllFiles)
                  forControlEvents:UIControlEventValueChanged];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self addKeyCommands];
    [super viewWillAppear:animated];
}

- (void) showSettings
{
    [self performSegueWithIdentifier:@"ToFilesPrefs" sender:self];
}

- (void) numberCommand:(id)sender
{
    NSInteger fileNumber = [[sender input] integerValue];
    if( [[CSVFileParser files] count] > fileNumber)
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:fileNumber inSection:0];
        [self.tableView selectRowAtIndexPath:path
                                    animated:NO
                              scrollPosition:NO];
        [self tableView:self.tableView didSelectRowAtIndexPath:path];
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
    UIKeyCommand *cmd;
    for( int i = 0 ; i < MIN([[CSVFileParser files] count], 10); ++i)
    {
        CSVFileParser *file = [[CSVFileParser files] objectAtIndex:i];
        cmd = [UIKeyCommand keyCommandWithInput:[NSString stringWithFormat:@"%d", i]
                                  modifierFlags:UIKeyModifierCommand
                                         action:@selector(numberCommand:)
                           discoverabilityTitle:[file tableViewDescription]];
        [self addKeyCommand:cmd];
    }
    cmd = [UIKeyCommand keyCommandWithInput:@"r"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(refreshAllFiles)
                       discoverabilityTitle:@"Reload files"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"n"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(addFileUsingURL)
                       discoverabilityTitle:@"Add using URL"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"n"
                              modifierFlags:UIKeyModifierCommand ^ UIKeyModifierShift
                                     action:@selector(addFileUsingURLList)
                       discoverabilityTitle:@"Add using URL for list of files"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"l"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(importLocalFile)
                       discoverabilityTitle:@"Import local file"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@","
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(showSettings)
                       discoverabilityTitle:@"Preferences"];
    [self addKeyCommand:cmd];
}

- (void) disableUI
{
    self.UIDisabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self deleteKeyCommands];
    self.view.alpha = 0.5;
}

- (void) enableUI
{
    self.UIDisabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self addKeyCommands];
    self.view.alpha = 1;
}

- (void) refreshAllFiles
{
    [[CSV_TouchAppDelegate sharedInstance] reloadAllFiles];
}

- (void) fileDownloadsStarted
{
    if( !self.refreshControl.refreshing )
    {
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height) animated:YES];
        [self.refreshControl beginRefreshing];
    }
    [self disableUI];
    [self.tableView reloadData];
}

- (void) allDownloadsCompleted
{
    [self.refreshControl endRefreshing];
    [self enableUI];
    [self.tableView reloadData];
}

- (BOOL) checkFileForSelection:(CSVFileParser *)file
{
    [file parseIfNecessary];
    [file updateColumnsInfo];
    if( !file.rawString )
    {
        return FALSE;
    }
    
    // Check if there seems to be a problem with the file preventing us from reading it
    if( [[file itemsWithResetShortdescriptions:NO] count] < 1 ||
       [file.columnNames count] == 0 )
    {
        return FALSE;
    }
    else
    {
        // We could read the file and will display it, but we should also check if we have any other problems
        // Check if something seems screwy...
        if( [file.shownColumnIndexes count] == 0 && [[file itemsWithResetShortdescriptions:NO] count] > 1 )
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No columns to show!"
                                                                           message:@"Probably reason: Separator has been changed and file was not correctly re-parsed; will try to fix it. Please try again, and if file still fails to load, try using another separator."
                                                                     okButtonTitle:@"OK"
                                                                         okHandler:nil];
            [self presentViewController:alert
                               animated:YES
                             completion:^(void){
                                 [file resetColumnsInfo];
                                 [CSVFileParser saveColumnNames];
            }];
        }        
        else if( file.problematicRow){
            return FALSE;
        }
        return TRUE;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[CSVFileParser files] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"FileCell" forIndexPath:indexPath];
    CSVFileParser *file = [[CSVFileParser files] objectAtIndex:indexPath.row];
    cell.textLabel.text = [file tableViewDescription];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

// Stop selection while downloads are in progress
- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self UIDisabled] ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVFileParser *selectedFile = [[CSVFileParser files] objectAtIndex:indexPath.row];
    if( selectedFile)
    {
        if( ![self checkFileForSelection:selectedFile]){
            [self performSegueWithIdentifier:@"ToParseError" sender:selectedFile];
        }
        else
        {
            [self performSegueWithIdentifier:@"ToItems" sender:selectedFile];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
        NSInteger index = indexPath.row;
        [self removeObjectAtIndex:index];
    }
}

- (void) removeObjectAtIndex:(NSInteger)index
{
    CSVFileParser *file = [[CSVFileParser files] objectAtIndex:index];
    [[NSFileManager defaultManager] removeItemAtPath:[file filePath] error:NULL];
    [[CSVFileParser files] removeObjectAtIndex:index];
    [self addKeyCommands]; // Files changed, so...
    [self.tableView reloadData];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue
{
}

@end
