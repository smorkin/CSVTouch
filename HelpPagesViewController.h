//
//  HelpPagesViewController.h
//  Heartfeed
//
//  Created by Simon Wigzell on 2016-01-25.
//  Copyright © 2016 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HowToController.h"

@class HelpPagesViewController;

@protocol HelpPagesViewDelegate <NSObject>
@required
- (NSInteger) numberOfPages;
- (NSString *) textForHelpPage:(NSInteger)index;
- (NSString *) titleForHelpPage:(NSInteger)index;
- (UIImage *) imageForHelpPage:(NSInteger)index;
@optional
- (void) helpPagesShowCompleted:(HelpPagesViewController *)controller;
@end


@interface HelpPagesViewController : UIPageViewController <UIPageViewControllerDataSource, HowToControllerDelegate>
@property NSMutableArray *helpPages;

- (instancetype) initWithDelegate:(id <HelpPagesViewDelegate>)delegate;

@end
