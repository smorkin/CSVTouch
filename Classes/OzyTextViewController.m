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

//- (void)viewDidAppear:(BOOL)animated
//{
//	[self.viewDelegate viewDidAppear:self.view controller:self];
//	[super viewDidAppear:animated];
//}
//
//- (void)viewDidDisappear:(BOOL)animated
//{
//	[self.viewDelegate viewDidDisappear:self.view controller:self];
//	[super viewDidDisappear:animated];
//}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


@end
