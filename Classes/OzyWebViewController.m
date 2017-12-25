//
//  OzyWebViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2010-04-11.
//  Copyright 2010 Ozymandias. All rights reserved.
//

#import "OzyWebViewController.h"
#import "OzymandiasAdditions.h"
#import "CSVDataViewController.h"

@implementation OzyWebViewController

@synthesize webView = _webView;

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
