//
//  OzyRotatableViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyRotatableViewController.h"
#import "OzymandiasAdditions.h"


@implementation OzyRotatableViewController

@synthesize viewDelegate = _viewDelegate;
@synthesize contentView = _contentView;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.viewDelegate viewDidAppear:self.view controller:self];	
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.viewDelegate viewDidDisappear:self.view controller:self];
	[super viewDidDisappear:animated];
}

- (void) dealloc
{
	self.viewDelegate = nil;
	[super dealloc];
}

@end
