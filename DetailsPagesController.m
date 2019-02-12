//
//  DetailsPagesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-03.
//

#import "DetailsPagesController.h"
#import "DetailsViewController.h"
#import "CSVPreferencesController.h"
#import "ItemPreferenceController.h"

@interface DetailsPagesController ()
@property (nonatomic, strong) NSArray<CSVRow *> *items;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, DetailsViewController *> *controllers;
@end

@implementation DetailsPagesController

- (void) setup
{
    self.delegate = self;
    self.dataSource = self;
    self.controllers = [NSMutableDictionary dictionary];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}

- (void) refreshViewControllers
{
    if( [self.viewControllers count] > 0 )
    {
        // So need a new version of the view controller for the current index, to make the view controller forget its cache of before/after. If not, we will crash since cached before/after controllers have wrong subviews
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

- (void) refreshViewControllersData
{
    for( DetailsViewController *controller in [self.controllers allValues])
    {
        controller.hasLoadedData = NO;
        [controller refreshData:YES];
    }
}

- (void) markViewControllersAsDirty
{
    for( DetailsViewController *controller in [self.controllers allValues])
    {
        controller.hasLoadedData = NO;
    }
}

- (void) showSettings
{
    [self showPreferences];
}

- (void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) increaseTableViewSize
{
    [CSVPreferencesController increaseDetailsFontSize];
    [self refreshViewControllersData];
}

- (void) decreaseTableViewSize
{
    [CSVPreferencesController decreaseDetailsFontSize];
    [self refreshViewControllersData];
}

- (void) goToPrevious
{
    if( [self.viewControllers count] > 0)
    {
        UIViewController *controller = [self.dataSource pageViewController:self viewControllerBeforeViewController:[self.viewControllers objectAtIndex:0]];
        if( controller ){
            [self setViewControllers:@[controller]
                           direction:UIPageViewControllerNavigationDirectionReverse
                            animated:YES
                          completion:nil];
        }
    }
}

- (void) goToNext
{
    if( [self.viewControllers count] > 0)
    {
        UIViewController *controller = [self.dataSource pageViewController:self viewControllerAfterViewController:[self.viewControllers objectAtIndex:0]];
        if( controller ){
            [self setViewControllers:@[controller]
                           direction:UIPageViewControllerNavigationDirectionForward
                            animated:YES
                          completion:nil];
        }
    }
}

- (void) toggleShowHidden
{
    [CSVPreferencesController setShowDeletedColumns:![CSVPreferencesController showDeletedColumns]];
    [self refreshViewControllersData];
}

- (void) addKeyCommands
{
    UIKeyCommand *cmd;
    cmd = [UIKeyCommand keyCommandWithInput:@"b"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(goBack)
                       discoverabilityTitle:@"Go back"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(goToPrevious)
                       discoverabilityTitle:@"Go to previous"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(goToNext)
                       discoverabilityTitle:@"Go to next"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"+"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(increaseTableViewSize)
                       discoverabilityTitle:@"Zoom in"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"-"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(decreaseTableViewSize)
                       discoverabilityTitle:@"Zoom out"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@"t"
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(toggleShowHidden)
                       discoverabilityTitle:@"Toggle show hidden"];
    [self addKeyCommand:cmd];
    cmd = [UIKeyCommand keyCommandWithInput:@","
                              modifierFlags:UIKeyModifierCommand
                                     action:@selector(showSettings)
                       discoverabilityTitle:@"Preferences"];
    [self addKeyCommand:cmd];
}

- (void) viewWillAppear:(BOOL)animated
{
    DetailsViewController *controller = [self controllerAtIndex:self.initialIndex];
    [self setViewControllers:@[controller]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    UIBarButtonItem *prefs = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"prefs_main"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(showPreferences)];
    self.navigationItem.rightBarButtonItem = prefs;
    [self addKeyCommands];
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if( ![CSVPreferencesController hasShown42ResizingNotes])
    {
        [CSVPreferencesController setHasShown42ResizingNotes];
        [self show42ResizingNote];
    }
}

- (void) show42ResizingNote
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Resizing changes!"
                                                                   message:@"This version uses new code for handling resizing in this window, and this means that your previous settings might result in too small/large text in this view. If so, just resize again (either by pinching or by using the settings button)."
                                                             okButtonTitle:@"OK"
                                                                 okHandler:nil];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
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

- (void) showPreferences
{
    ItemPreferenceController* controller = [[self storyboard] instantiateViewControllerWithIdentifier:@"ItemPreferences"];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.delegate = self;
    controller.popoverPresentationController.permittedArrowDirections =
    UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
    controller.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    controller.pageController = self;
    controller.preferredContentSize = CGSizeMake(300, 300);
    [self presentViewController:controller animated:YES completion:nil];
}

// To avoid full screen presentation
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

@end
