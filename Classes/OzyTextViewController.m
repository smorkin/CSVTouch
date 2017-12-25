//
//  OzyTextViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 18/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyTextViewController.h"
#import "OzymandiasAdditions.h"

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


@end
