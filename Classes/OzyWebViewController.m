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

@end
