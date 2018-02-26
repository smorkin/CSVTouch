//
//  AppPrefsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-27.
//

#import "AppPrefsViewController.h"
#import "CSVPreferencesController.h"

@implementation AppPrefsViewController

- (void) viewWillAppear:(BOOL)animated
{
    usePassword.onTintColor = [[UIView appearance] tintColor];
    synchronizeFiles.onTintColor = [[UIView appearance] tintColor];
    [super viewWillAppear:animated];
    [self synchUI];
}

- (void) synchUI
{
    usePassword.on = [CSVPreferencesController usePassword];
    synchronizeFiles.on = [CSVPreferencesController synchronizeDownloadedFiles];
    if( [CSVPreferencesController maxSafeBackgroundMinutes] != NSIntegerMax){
        passwordTimeout.text = [NSString stringWithFormat:@"%ld", [CSVPreferencesController maxSafeBackgroundMinutes]];
    }
}

- (IBAction)somethingChanged:(id)sender
{
    //    if( sender == caseSensitiveSort){
    //        [CSVPreferencesController setCaseSensitiveSort:caseSensitiveSort.on];
    //    }
    [self synchUI];
}

@end
