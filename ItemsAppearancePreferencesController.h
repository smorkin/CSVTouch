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
    IBOutlet UISwitch *fixedWidth;
    IBOutlet UISwitch *predefinedWidths;
    IBOutlet UISwitch *useWordSeparator;
}

- (IBAction)switchChanged:(id)sender;

@end