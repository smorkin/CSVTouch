//
//  AppPrefsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-27.
//

#import <UIKit/UIKit.h>

@interface AppPrefsViewController : UIViewController
{
    IBOutlet UISwitch *usePassword;
    IBOutlet UISwitch *synchronizeFiles;
    IBOutlet UIDatePicker *reloadTime;
    IBOutlet UITextField *passwordTimeout;
}

- (IBAction)somethingChanged:(id)sender;

@end
