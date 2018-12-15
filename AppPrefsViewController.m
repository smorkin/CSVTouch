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
    [downloadTimePicker selectRow:[CSVPreferencesController configuredDownloadHour] inComponent:0 animated:NO];
    [downloadTimePicker selectRow:[CSVPreferencesController configuredDownloadMinute] inComponent:1 animated:NO];
    downloadTimePicker.userInteractionEnabled = useAutomatedDownload.on;
    downloadTimePicker.alpha = useAutomatedDownload.on ? 1.0 : 0.5;
    downloadTimePickerLabel.enabled = useAutomatedDownload.on;
    synchronizeFiles.on = [CSVPreferencesController synchronizeDownloadedFiles];
    NSString *s = ![[[CSVPreferencesController lastUsedListURL] absoluteString] isEqualToString:@""] ?
    [[CSVPreferencesController lastUsedListURL] absoluteString] : @"no file list URL has been used)";
    fileListURLForSynchronizing.text = [NSString stringWithFormat:@"(%@)", s];
    fileListURLForSynchronizing.enabled = [CSVPreferencesController canSynchronizeFiles];
}

- (IBAction)somethingChanged:(id)sender
{
    if( sender == useAutomatedDownload)
    {
        [CSVPreferencesController setUseAutomatedDownload:useAutomatedDownload.on];
        [[CSV_TouchAppDelegate sharedInstance] scheduleAutomatedDownload];
    }
    else if( sender == synchronizeFiles )
    {
        [CSVPreferencesController setSynchronizeDownloadedFiles:synchronizeFiles.on];
    }
    [self synchUI];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch(component)
    {
        case 0:
            [CSVPreferencesController setConfiguredDownloadHour:row
                                                         minute:[CSVPreferencesController configuredDownloadMinute]];
            break;
        case 1:
            [CSVPreferencesController setConfiguredDownloadHour:[CSVPreferencesController
                                                                 configuredDownloadHour] minute:row];
            break;
        default:
            break;
    }
    [[CSV_TouchAppDelegate sharedInstance] scheduleAutomatedDownload];
    [self synchUI];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch(component)
    {
        case 0:
            return 24;
        case 1:
            return 60;
        default:
            return 0;
    }
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch(component)
    {
        case 0:
        case 1:
            return [NSString stringWithFormat:@"%02ld", (long)row];
       default:
            return nil;
    }
}
@end
