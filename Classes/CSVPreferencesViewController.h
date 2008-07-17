//
//  CSVPreferencesViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 14/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OzyRotatableViewController;

@interface CSVPreferencesViewController : UINavigationController <UITableViewDelegate>
{
	IBOutlet OzyRotatableViewController *prefsSelectionController;
	IBOutlet OzyRotatableViewController *dataPrefsController;
	IBOutlet OzyRotatableViewController *sortingPrefsController;
	IBOutlet OzyRotatableViewController *appearancePrefsController;
	IBOutlet OzyRotatableViewController *aboutController;
}

- (void) applicationDidFinishLaunching;

@end
