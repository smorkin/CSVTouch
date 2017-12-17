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
    [lpgr release];
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
            [[CSV_TouchAppDelegate sharedInstance] showFileInfo:(CSVFileParser *)[[self objects] objectAtIndex:indexPath.row]];
        }
    }
    else
    {
        longPress.enabled = TRUE;
    }
}
- (void) awakeFromNib
{
    [super awakeFromNib];
    _sharedInstance = self;
    [self configureToolbarButtons];
    [self configureGestures];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.navigationController.toolbarHidden = NO;
    if( [CSVPreferencesController simpleMode])
    {
        self.navigationController.navigationItem.rightBarButtonItem = nil;
        self.editable = NO;
    }    
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

- (UIBarButtonItem *) doneItemWithSelector:(SEL)selector
{
    return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:selector] autorelease];
}

- (UIBarButtonItem *) refreshFilesItem
{
    UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Refresh…" style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(toggleRefreshFiles)] autorelease];
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
                         withObject:[self doneItemWithSelector:@selector(toggleRefreshFiles)]];
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

//- (void) showFileInfo:(CSVFileParser *)fp
//{
//    [self configureFileEncodings];
//
//    self.fileInspected = fp;
//
//    NSError *error;
//    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fp filePath] error:&error];
//
//    if( fileAttributes )
//    {
//        NSMutableString *s = [NSMutableString string];
//        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
//        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
//        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//        [s appendFormat:@"Size: %.2f KB\n\n", ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
//        if( [fp URL] && [[fp URL] isEqualToString:MANUALLY_ADDED_URL_VALUE] )
//            [s appendFormat:@"Imported: %@\n\n",
//             (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"n/a")];
//        else
//            [s appendFormat:@"Downloaded: %@\n\n",
//             (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"Available after next download")];
//        [s appendFormat:@"File: %@\n\n", fp.filePath];
//        fileInfo.text = s;
//    }
//    else
//    {
//        fileInfo.text = [error localizedDescription];
//    }
//    if( fp.hideAddress )
//    {
//        newFileURL.text = @"<address hidden>";
//    }
//    else
//    {
//        newFileURL.text = fp.URL;
//    }
//    [self synchronizeFileEncoding];
//    [[self dataController] presentViewController:fileViewController
//                                        animated:YES
//                                      completion:NULL];
//}
//

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSVFileParser *selectedFile = [[self objects] objectAtIndex:indexPath.row];
    if( self.refreshFilesInProgress && selectedFile)
    {
        [[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:[selectedFile URL]];
    }
    else if( selectedFile)
    {
        [[CSVDataViewController sharedInstance] fileWasSelected:selectedFile];
    }
}

@end
