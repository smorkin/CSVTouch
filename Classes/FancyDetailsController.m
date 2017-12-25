//
//  FancyDetailsController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-25.
//

#import "FancyDetailsController.h"
#import "CSVDataViewController.h"

@interface FancyDetailsController ()

@end

@implementation FancyDetailsController

- (void) configureNavigationBar
{
    
    UIBarButtonItem *move = [[UIBarButtonItem alloc] initWithTitle:@"Next view"
                                                             style:UIBarButtonItemStylePlain
                                                            target:[CSVDataViewController sharedInstance]
                                                            action:@selector(gotoNextDetailsView)];
    self.navigationItem.rightBarButtonItem = move;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self configureNavigationBar];
}

@end
