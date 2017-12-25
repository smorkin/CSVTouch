//
//  OzyWebViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2010-04-11.
//  Copyright 2010 Ozymandias. All rights reserved.
//

#import "OzyWebViewController.h"
#import "OzymandiasAdditions.h"

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


@end
