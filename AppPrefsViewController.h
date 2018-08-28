//
//  AppPrefsViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-27.
//

#import <UIKit/UIKit.h>

@interface AppPrefsViewController : UIViewController
{
    IBOutlet UISwitch *useAutomatedDownload;
    IBOutlet UIDatePicker *downloadTime;
}

- (IBAction)somethingChanged:(id)sender;

@end
