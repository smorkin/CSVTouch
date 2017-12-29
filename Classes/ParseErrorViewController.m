//
//  ParseErrorViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ParseErrorViewController.h"

@interface ParseErrorViewController ()
@property (nonatomic, copy) UIColor *initialToolbarColor;
@end

@implementation ParseErrorViewController

- (void) viewWillAppear:(BOOL)animated
{
    self.title = @"ERROR READING FILE";
    self.textView.text = self.errorText;
    self.initialToolbarColor = self.navigationController.navigationBar.barTintColor;
    self.navigationController.navigationBar.barTintColor = [UIColor redColor];
   self.navigationItem.rightBarButtonItem = nil;
    self.navigationController.toolbarHidden = YES;
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.barTintColor = self.initialToolbarColor;
    [super viewWillDisappear:animated];
}

@end
