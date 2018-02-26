//
//  FilesParsingPreferencesViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-26.
//

#import <UIKit/UIKit.h>

@interface FilesParsingPreferencesViewController : UIViewController
{
    IBOutlet UISwitch *alternativeParsing;
    IBOutlet UISwitch *keepQuotes;
    IBOutlet UISegmentedControl *encodingControl;
    IBOutlet UISegmentedControl *delimiterControl;
}

- (IBAction)somethingChanged:(id)sender;


@end
