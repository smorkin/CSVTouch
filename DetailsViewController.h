//
//  DetailsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-29.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "CSVRow.h"

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) CSVRow *row;
@property (nonatomic, assign) BOOL hasLoadedData;

- (void) refreshData:(BOOL)forceRefresh;

@end


