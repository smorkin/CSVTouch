//
//  CSVDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 23/05/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVDataViewController.h"
#import "CSV_TouchAppDelegate.h"

@implementation CSVDataViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    [CSV_TouchAppDelegate sharedInstance].navigationController = self;
    self.delegate = [CSV_TouchAppDelegate sharedInstance];
	return self;
}

@end
