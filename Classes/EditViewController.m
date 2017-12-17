//
//  EditViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-17.
//

#import "EditViewController.h"
#import "CSVDataViewController.h"

@interface EditViewController ()

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
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[CSVDataViewController sharedInstance] editDone:self];
    [super viewWillDisappear:animated];
}

- (void) resetColumns
{
    [[CSVDataViewController sharedInstance] resetColumnNamesForCurrentFile];
}
@end
