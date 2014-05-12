//
//  IntroViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2014-03-15.
//
//

#import "HowToController.h"
#import <UIKit/UIKit.h>

@class IntroViewController;

@protocol IntroViewControllerDelegate <NSObject>

@required
- (void) dismissHowToController:(IntroViewController *)controller;
- (UIWindow *) window;
@end


@interface IntroViewController : NSObject
<UIPageViewControllerDataSource,
HowToControllerDelegate,
UIToolbarDelegate>
{
    NSMutableArray *_howToControllers;
}
@property (strong, nonatomic) UIPageViewController *pageController;
@property (nonatomic, assign) id <IntroViewControllerDelegate> delegate;

- (void) startHowToShowing:(id <IntroViewControllerDelegate>) delegate;

@end
