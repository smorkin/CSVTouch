//
//  CSVDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVDataViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "FilesViewController.h"
#import "FadeAnimator.h"
#import "CSVPreferencesController.h"
#import "HelpPagesViewController.h"
#import "HelpPagesDelegate.h"

@interface CSVDataViewController ()
@property BOOL isPushing;
@end

@implementation CSVDataViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    [CSV_TouchAppDelegate sharedInstance].navigationController = self;
    self.delegate = self;
	return self;
}

- (void) showHelp
{
    HelpPagesDelegate *delegate = [[HelpPagesDelegate alloc] init];
    HelpPagesViewController *controller = [[HelpPagesViewController alloc] initWithDelegate:delegate];
    
    [self pushViewController:controller animated:YES];
}

- (void) show40Notes
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Welcome to 4.0!"
                                                                   message:@"This is a big update so here are a few new things (check home page for more details):\n\n- Pull to reload all files\n-Long-click to check & reload a single file\n- Load files using the 'Files' app (so e.g. import from DropBox can be done inside the app\n-Pinch-to-zoom in views supporting size changes\n\nNote that due to the large changes, you might have to redo some settings but since all settings are now inside the app and takes effect immediately, this should be simple. I hope!"
                                                             okButtonTitle:@"OK"
                                                                 okHandler:nil];
    [self.topViewController presentViewController:alert
                                         animated:YES
                                       completion:nil];
}

- (IBAction)dismissSettingsViewAndShowHelp:(UIStoryboardSegue *)sender
{
    [self performSelector:@selector(showHelp) withObject:nil afterDelay:0];
}

// Now, a bunch of things to fix https://stackoverflow.com/questions/34942571/how-to-enable-back-left-swipe-gesture-in-uinavigationcontroller-after-setting-le/43433530#43433530
- (void) viewDidLoad
{
    [super viewDidLoad];
    self.interactivePopGestureRecognizer.delegate = self;
    self.view.backgroundColor = [CSVPreferencesController systemBackgroundColor];
    
    // Show the Add file window in case no files are present
    if( [[CSVFileParser files] count] == 0 && ![CSVPreferencesController hasShownHowTo])
    {
        [self showHelp];
        // This is a bit special since it is shown when looking at details, but only if you were already using the app before resizing code changed -> since this is the first time you are running the app, no need to notify about resizing differences
        [CSVPreferencesController setHasShown42ResizingNotes];
    }
    else if( ![CSVPreferencesController hasShown40Notes])
    {
        [self performSelector:@selector(show40Notes) withObject:nil afterDelay:1];
        [CSVPreferencesController setHasShown42ResizingNotes]; // Similar reason as above
    }
    [CSVPreferencesController setHasShown40Notes]; // Help includes notes

}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // https://stackoverflow.com/questions/34942571/how-to-enable-back-left-swipe-gesture-in-uinavigationcontroller-after-setting-le/43433530#43433530
    self.isPushing = YES;
    [super pushViewController:viewController animated:animated];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    self.isPushing = NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        // Disable pop gesture in two situations:
        // 1) when the pop animation is in progress
        // 2) when user swipes quickly a couple of times and animations don't have time to be performed
        return [self.viewControllers count] > 1 && !self.isPushing;
    } else {
        // default value
        return YES;
    }
}


// For phasing in view
- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC
{
    if( ([fromVC isKindOfClass:[FilesViewController class]] && [toVC isKindOfClass:[FileDataViewController class]]) ||
       ([fromVC isKindOfClass:[FileDataViewController class]] && [toVC isKindOfClass:[FilesViewController class]]))
    {
        return [[FadeAnimator alloc] init];
    }
    return nil;
}


@end
