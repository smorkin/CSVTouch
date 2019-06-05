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

// Refreshing data inside all view controllers
- (void) refreshViewControllersData;

// Softer, just marking all as dirty (used e.g. when change is trigged by one if the view controllers so it can redraw itself and needs the others to be redrawn when necessary)
- (void) markViewControllersAsDirty;
@end
