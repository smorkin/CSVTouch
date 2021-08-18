//
//  AddFilesSelectionController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-04.
//

#import "AddFilesSelectionController.h"
#import "FilesViewController.h"

@interface AddFilesSelectionController ()

@end

@implementation AddFilesSelectionController

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.tableView layoutIfNeeded];
    CGSize s = [self.tableView contentSize];
    self.preferredContentSize = s;
}

- (void) awakeFromNib
{
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if( @available(iOS 11, *))
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    [super awakeFromNib];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddFilesCell" forIndexPath:indexPath];
    cell.textLabel.textColor = [[UIView appearance] tintColor];

    if( indexPath.row == 0 )
    {
        cell.textLabel.text = @"Add using URL";
    }
    else if( indexPath.row == 1 )
    {
        cell.textLabel.text = @"Add using URL for list of files";
    }
    else if( indexPath.row == 2 )
    {
        cell.textLabel.text = @"Import local file(s)";
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^()
     {
         if( indexPath.row == 0 ){
             [[FilesViewController sharedInstance] addFileUsingURL];
         }
         else if( indexPath.row == 1 ){
             [[FilesViewController sharedInstance] addFileUsingURLList];
         }
         else if( indexPath.row == 2 ){
             [[FilesViewController sharedInstance] importLocalFile];
         }
     }];
}

@end
