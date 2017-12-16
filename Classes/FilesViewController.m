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

@interface FilesViewController ()

@property (assign) BOOL refreshFilesInProgress;
@property (assign) BOOL showFileInfoInProgress;

@end

@implementation FilesViewController

static FilesViewController *_sharedInstance = nil;

+ (instancetype) sharedInstance
{
    return _sharedInstance;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _sharedInstance = self;
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh one"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self.navigationController
                                                                   action:@selector(toggleRefreshFiles)];
    UIBarButtonItem *refreshAllItems = [[UIBarButtonItem alloc] initWithTitle:@"Refresh all"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(refreshAllFiles)];
    UIBarButtonItem *loadFileListItem = [[UIBarButtonItem alloc] initWithTitle:@"List+"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(loadFileList)];
    UIBarButtonItem *infoItem = [[UIBarButtonItem alloc] initWithTitle:@"Info"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self.navigationController
                                                                action:@selector(toggleShowFileInfo:)];
    
    // Now, add in order:
    NSMutableArray *items = [NSMutableArray array];
    if( [CSVPreferencesController simpleMode])
    {
        [items addObject:refreshItem];
        if([CSVPreferencesController lastUsedListURL])
            [items addObject:refreshAllItems];
        [items addObject:infoItem];
    }
    else
    {
        [items addObject:refreshItem];
        [items addObject:refreshAllItems];
        [items addObject:loadFileListItem];
        [items addObject:infoItem];
    }
    self.toolbarItems = items;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.refreshFilesInProgress )
    {
        [[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:[(CSVFileParser *)[[self objects] objectAtIndex:indexPath.row] URL]];
    }
    else if( self.showFileInfoInProgress )
    {
        [[CSV_TouchAppDelegate sharedInstance] showFileInfo:(CSVFileParser *)[[self objects] objectAtIndex:indexPath.row]];
    }
    else
    {
        CSVFileParser *selectedFile = [[self objects] objectAtIndex:indexPath.row];
        [[CSVDataViewController sharedInstance] fileWasSelected:selectedFile];
    }
}

@end
