//
//  ItemPreferenceController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-14.
//

#import <UIKit/UIKit.h>
#import "DetailsPagesController.h"

@interface ItemPreferenceController : UIViewController
{
    IBOutlet UISegmentedControl *viewSelection;
    IBOutlet UISwitch *showHidden;
}

@property (nonatomic, weak) DetailsPagesController *pageController;

- (IBAction)showHiddenChanged:(id)sender;
- (IBAction)viewSelectionChanged:(id)sender;

@end
