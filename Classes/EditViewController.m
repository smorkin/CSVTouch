//
//  EditViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-17.
//

#import "EditViewController.h"
#import "CSVDataViewController.h"

@interface EditViewController ()
@property (nonatomic, weak) CSVFileParser *file;
@end

@implementation EditViewController

- (void) viewWillAppear:(BOOL)animated
{
    [[self tableView] setEditing:YES animated:NO];
    self.editable = YES;
    self.reorderable = YES;
    self.size = OZY_NORMAL;
    [self setSectionTitles:[NSArray arrayWithObject:@"Select & Arrange Columns"]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(resetColumns)];
    self.navigationController.toolbarHidden = YES;
    [self dataLoaded];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[CSVDataViewController sharedInstance] editDone:self];
    [super viewWillDisappear:animated];
}

- (void) resetColumns
{
    [self.file resetColumnsInfo];
    [self.file itemsWithResetShortdescriptions:YES];
    [CSVFileParser saveColumnNames];
    [self dataLoaded];
}

- (void) removeObjectAtIndex:(NSInteger)index
{
    [self.objects removeObjectAtIndex:index];
    [self.file updateColumnsInfoWithShownColumns:self.objects];
    [self.file itemsWithResetShortdescriptions:YES];
    [CSVFileParser saveColumnNames];
    [self dataLoaded];
}

- (void) movingObjectFrom:(NSInteger)from to:(NSInteger)to
{
    [super movingObjectFrom:from to:to];
    [self.file updateColumnsInfoWithShownColumns:self.objects];
    [self.file itemsWithResetShortdescriptions:YES];
    [CSVFileParser saveColumnNames];
    [self dataLoaded];
}

- (void) dataLoaded
{
    self.objects = [self.file.shownColumnNames mutableCopy];
    [super dataLoaded];
}
@end
