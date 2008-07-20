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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if( [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(allowRotation)] )
		return [(id <OzymandiasApplicationDelegate>)[[UIApplication sharedApplication] delegate] allowRotation];
	else
		return YES;
}

@end
