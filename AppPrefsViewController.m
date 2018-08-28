//
//  AppPrefsViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-27.
//

#import "AppPrefsViewController.h"
#import "CSVPreferencesController.h"
#import "CSV_TouchAppDelegate.h"

@implementation AppPrefsViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self synchUI];
}

- (void) synchUI
{
    useAutomatedDownload.on = [CSVPreferencesController useAutomatedDownload];
    if( [CSVPreferencesController configuredDownloadTime])
    {
        downloadTime.date = [CSVPreferencesController configuredDownloadTime];
    }
    downloadTime.enabled = useAutomatedDownload.on;
}

- (IBAction)somethingChanged:(id)sender
{
    if( sender == useAutomatedDownload)
    {
        [CSVPreferencesController setUseAutomatedDownload:useAutomatedDownload.on];
        [[CSV_TouchAppDelegate sharedInstance] scheduleAutomatedDownload];
    }
    else if( sender == downloadTime )
    {
        [CSVPreferencesController setConfiguredDownloadTime:downloadTime.date];
        [[CSV_TouchAppDelegate sharedInstance] scheduleAutomatedDownload];
    }
    [self synchUI];
}

@end
