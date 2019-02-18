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
    IBOutlet UIButton *increaseSize;
    IBOutlet UIButton *decreaseSize;
    IBOutlet UISwitch *showImages;
    IBOutlet UILabel *customCSSInfo;
}

@property (nonatomic, weak) DetailsPagesController *pageController;

- (IBAction)showHiddenChanged:(id)sender;
- (IBAction)viewSelectionChanged:(id)sender;
- (IBAction)increaseSize:(id)sender;
- (IBAction)decreaseSize:(id)sender;
- (IBAction)showImages:(id)sender;

@end
