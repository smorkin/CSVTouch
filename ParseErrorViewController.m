//
//  ParseErrorViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ParseErrorViewController.h"

@interface ParseErrorViewController ()
@end

@implementation ParseErrorViewController

- (void) viewWillAppear:(BOOL)animated
{
    self.title = @"ERROR READING FILE";
    self.textView.text = self.errorText;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [super viewWillAppear:animated];
}

@end
