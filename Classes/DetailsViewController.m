//
//  DetailsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-29.
//

#import "DetailsViewController.h"

@interface DetailsViewController ()
@property (nonatomic, strong) UIBarButtonItem *viewSelection;
@end

@implementation DetailsViewController

- (void) setup
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.webView = [[WKWebView alloc] init];
    self.simpleView = [[UITextView alloc] init];
    self.fancyView = [[UITableView alloc] init];
    [self.fancyView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DetailsCell"];
    self.fancyView.dataSource = self;
    self.fancyView.delegate = self;
    UISegmentedControl *c = [[UISegmentedControl alloc] initWithItems: @[@"1", @"2", @"3"]];
    [c addTarget:self
          action:@selector(viewSelectionChanged)
forControlEvents:UIControlEventValueChanged];
    self.viewSelection = [[UIBarButtonItem alloc] initWithCustomView:c];
    self.view = self.simpleView;
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}
- (void) viewWillAppear:(BOOL)animated
{
    self.simpleView.text = [self.row longDescriptionWithHiddenValues:NO];
    self.navigationController.toolbarHidden = YES;
    [(UISegmentedControl *)self.viewSelection.customView setSelectedSegmentIndex:0];
    self.navigationItem.rightBarButtonItem = self.viewSelection;
    [super viewWillAppear:animated];
}

- (void) viewSelectionChanged
{
    NSInteger viewToSelect = [(UISegmentedControl *)self.viewSelection.customView selectedSegmentIndex];
    if( viewToSelect == 0 ){
        self.view = self.simpleView;
    }
    else if( viewToSelect == 1 ){
        self.view = self.fancyView;
    }
    else if( viewToSelect == 2 ){
        self.view = self.webView;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.row longDescriptionInArrayWithHiddenValues:NO] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.fancyView dequeueReusableCellWithIdentifier:@"DetailsCell"];
    cell.textLabel.text = [[self.row longDescriptionInArrayWithHiddenValues:NO] objectAtIndex:indexPath.row];
    return cell;

}

@end
