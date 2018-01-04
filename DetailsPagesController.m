//
//  DetailsPagesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-03.
//

#import "DetailsPagesController.h"
#import "DetailsViewController.h"
#import "CSVPreferencesController.h"

@interface DetailsPagesController ()
@property (nonatomic, strong) NSArray<CSVRow *> *items;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DetailsViewController *> *controllers;
@property (nonatomic, strong) UIBarButtonItem *viewSelection;
@end

@implementation DetailsPagesController

- (void) setup
{
    self.delegate = self;
    self.dataSource = self;
    UISegmentedControl *c = [[UISegmentedControl alloc] initWithItems: @[@"1", @"2", @"3"]];
    [c addTarget:self
          action:@selector(viewSelectionChanged)
forControlEvents:UIControlEventValueChanged];
    self.viewSelection = [[UIBarButtonItem alloc] initWithCustomView:c];
    self.controllers = [NSMutableDictionary dictionary];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}

- (void) viewSelectionChanged
{
    NSInteger viewToSelect = [(UISegmentedControl *)self.viewSelection.customView selectedSegmentIndex];
    [CSVPreferencesController setSelectedDetailsView:viewToSelect];
    
    if( [self.viewControllers count] > 0 )
    {
        // So need a new version of the view controller for the current index, to make age view controller
        // forget its cache of before/after. If not, we will crash since cached before/after have wrong subviews
        NSInteger currentIndex = -1;
        DetailsViewController *currentController = [self.viewControllers objectAtIndex:0];
        for( NSInteger i = 0 ; i < [self.items count] ; i++)
        {
            if( currentController.row == [self.items objectAtIndex:i]){
                currentIndex = i;
                break;
            }
        }
        [self.controllers removeAllObjects];
        [self setViewControllers:@[[self controllerAtIndex:currentIndex]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    DetailsViewController *controller = [self controllerAtIndex:self.initialIndex];
    [self setViewControllers:@[controller]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    NSInteger viewToSelect = [CSVPreferencesController selectedDetailsView];
    if( viewToSelect >= [(UISegmentedControl *)self.viewSelection.customView numberOfSegments] ){
        viewToSelect = 0;
    }
    [(UISegmentedControl *)self.viewSelection.customView setSelectedSegmentIndex:viewToSelect];
    self.navigationItem.rightBarButtonItem = self.viewSelection;
    [super viewWillAppear:animated];
}

- (DetailsViewController *) controllerAtIndex:(NSInteger)index
{
    if( index < 0 || index >= self.items.count){
        return nil;
    }
    
    DetailsViewController *controller = [self.controllers objectForKey:[NSNumber numberWithInteger:index]];
    if( !controller )
    {
        controller = [[DetailsViewController alloc] init];
        controller.row = [self.items objectAtIndex:index];
        controller.title = [NSString stringWithFormat:@"%ld/%lu", (long)index+1, (unsigned long)self.items.count];
        [self.controllers setObject:controller forKey:[NSNumber numberWithInteger:index]];
    }
    return controller;
}


- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController
               viewControllerBeforeViewController:(UIViewController *)viewController
{
    CSVRow *item = [(DetailsViewController *)viewController row];
    return [self controllerAtIndex:[self.items indexOfObject:item]-1];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    CSVRow *item = [(DetailsViewController *)viewController row];
    return [self controllerAtIndex:[self.items indexOfObject:item]+1];

}

@end
