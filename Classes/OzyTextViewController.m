//
//  OzyTextViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 18/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyTextViewController.h"
#import "OzymandiasAdditions.h"
#import "CSVDataViewController.h"

@implementation OzyTextViewController

@synthesize textView = _textView;

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

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
