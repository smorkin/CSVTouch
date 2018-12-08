//
//  DetailsPagesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-03.
//

#import <UIKit/UIKit.h>
#import "CSVRow.h"

@interface DetailsPagesController : UIPageViewController <UIPageViewControllerDataSource,
UIPageViewControllerDelegate,
UIPopoverPresentationControllerDelegate>

@property (nonatomic, assign) NSInteger initialIndex;

- (void) setItems:(NSArray<CSVRow *> *)items;

// This is a hard one, actually updating which view is shown etc
- (void) refreshViewControllers;

// Softer, keeping the same view in the controller and just refreshing data
- (void) refreshViewControllersData;
@end
