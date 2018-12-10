//
//  AppPrefsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-27.
//

#import <UIKit/UIKit.h>

@interface AppPrefsViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UISwitch *useAutomatedDownload;
    IBOutlet UIPickerView *downloadTimePicker;
    IBOutlet UILabel *downloadTimePickerLabel;
}

- (IBAction)somethingChanged:(id)sender;

@end
