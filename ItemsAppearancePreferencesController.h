//
//  ItemsAppearancePreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-25.
//

#import <UIKit/UIKit.h>

@interface ItemsAppearancePreferencesController : UIViewController
{
    IBOutlet UISwitch *groupItems;
    IBOutlet UISwitch *groupNumbers;
    IBOutlet UISwitch *monospaced;
    IBOutlet UISwitch *useWordSeparator;
    IBOutlet UISwitch *multiLine;
    IBOutlet UILabel *fixedWidthAlternativeLabel;
    IBOutlet UISegmentedControl *fixedWidthAlternative;
}

- (IBAction)switchChanged:(id)sender;

@end
