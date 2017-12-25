//
//  OzyRotatableTabBarController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyRotatableTabBarController.h"
#import "OzymandiasAdditions.h"
#import "CSVPreferencesController.h"

@implementation OzyRotatableTabBarController

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

@end
