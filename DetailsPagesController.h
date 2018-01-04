//
//  DetailsPagesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-03.
//

#import <UIKit/UIKit.h>
#import "CSVRow.h"
#import "DetailsViewController.h"

@interface DetailsPagesController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, assign) NSInteger initialIndex;

- (void) setItems:(NSArray<CSVRow *> *)items;
@end
