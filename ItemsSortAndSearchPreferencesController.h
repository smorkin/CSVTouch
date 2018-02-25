//
//  ItemsSortAndSearchPreferencesController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-25.
//

#import <UIKit/UIKit.h>

@interface ItemsSortAndSearchPreferencesController : UIViewController
{
    IBOutlet UISwitch *caseSensitiveSort;
    IBOutlet UISwitch *numericSort;
    IBOutlet UISwitch *literalSort;
    IBOutlet UISwitch *correctSort;
    IBOutlet UISwitch *smartSearchClearing;
}

- (IBAction)switchChanged:(id)sender;

@end
