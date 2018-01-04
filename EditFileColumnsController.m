//
//  EditViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-17.
//

#import "EditFileColumnsController.h"
#import "CSVFileParser.h"

@interface EditFileColumnsController ()
@property (nonatomic, weak) CSVFileParser *file;
@property (nonatomic, assign) BOOL columnsChanged;
@property (nonatomic, strong) NSMutableArray *important;
@property (nonatomic, strong) NSMutableArray *notImportant;
@end

@implementation EditFileColumnsController

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView setEditing:YES animated:NO];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(resetColumns)];
    self.navigationController.toolbarHidden = YES;
    [self loadData];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if( self.columnsChanged)
    {
        NSMutableArray *rows = [self.file itemsWithResetShortdescriptions:YES];
        [rows sortUsingSelector:[CSVRow compareSelector]];
        [CSVFileParser saveColumnNames];
    }
    [super viewWillDisappear:animated];
}

- (void) resetColumns
{
    [self.file resetColumnsInfo];
    [self loadData];
    self.columnsChanged = TRUE;
}

- (void) loadData
{
    self.important = [self.file.shownColumnNames mutableCopy];
    self.notImportant = [self.file.columnNames mutableCopy];
    [self.notImportant removeObjectsInArray:self.important];
    [self.notImportant sortUsingSelector:@selector(localizedStandardCompare:)];
    [self.tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.section == 0 ){
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    if( fromIndexPath.section == 0 && toIndexPath.section == 0 ){
        id item = [self.important objectAtIndex:fromIndexPath.row];
        [self.important removeObjectAtIndex:fromIndexPath.row];
        [self.important insertObject:item atIndex:toIndexPath.row];
    }
    else if( fromIndexPath.section == 1 && toIndexPath.section == 1 ){
        id item = [self.notImportant objectAtIndex:fromIndexPath.row];
        [self.notImportant removeObjectAtIndex:fromIndexPath.row];
        [self.notImportant insertObject:item atIndex:toIndexPath.row];
    }
    else if( fromIndexPath.section == 0 && toIndexPath.section == 1 ){
        id item = [self.important objectAtIndex:fromIndexPath.row];
        [self.important removeObjectAtIndex:fromIndexPath.row];
        [self.notImportant insertObject:item atIndex:toIndexPath.row];
    }
    else if( fromIndexPath.section == 1 && toIndexPath.section == 0 ){
        id item = [self.notImportant objectAtIndex:fromIndexPath.row];
        [self.notImportant removeObjectAtIndex:fromIndexPath.row];
        [self.important insertObject:item atIndex:toIndexPath.row];
    }
    [self.file updateColumnsInfoWithShownColumns:self.important];
    [self loadData];
    self.columnsChanged = TRUE;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.section == 0 && editingStyle == UITableViewCellEditingStyleDelete )
    {
        [self.important removeObjectAtIndex:indexPath.row];
        [self.file updateColumnsInfoWithShownColumns:self.important];
        [self loadData];
        self.columnsChanged = TRUE;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.section == 0 ){
        return YES;
    }
   return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( section == 0 )
    {
        return self.important.count;
    }
    else if( section == 1 )
    {
        return self.notImportant.count;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( section == 0 )
    {
        return @"Important columns";
    }
    else if( section == 1 )
    {
        return @"Non-important columns (unsorted)";
    }
    return nil;

}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"EditColumnCell"];
    
    if( indexPath.section == 0 )
    {
        cell.textLabel.text = [self.important objectAtIndex:indexPath.row];
    }
    else if( indexPath.section == 1 )
    {
        cell.textLabel.text = [self.notImportant objectAtIndex:indexPath.row];
    }
    return cell;
}

@end
