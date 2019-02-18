//
//  ItemPreferenceController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-14.
//

#import "ItemPreferenceController.h"
#import "CSVPreferencesController.h"
#import "CSSProvider.h"

@interface ItemPreferenceController ()

@end

@implementation ItemPreferenceController

- (void) viewWillAppear:(BOOL)animated
{
    [self synchUI];
    [super viewWillAppear:animated];
}

- (void) synchUI
{
    showHidden.on = [CSVPreferencesController showDeletedColumns];
    viewSelection.selectedSegmentIndex = [CSVPreferencesController selectedDetailsView];
    increaseSize.enabled = [CSVPreferencesController canIncreaseDetailsFontSize];
    decreaseSize.enabled = [CSVPreferencesController canDecreaseDetailsFontSize];
    showImages.on = [CSVPreferencesController showInlineImages];
    customCSSInfo.text = [CSSProvider customCSSExists] ? @"Custom CSS: Yes" : @"Custom CSS: No";
}

- (IBAction) showHiddenChanged:(id)sender
{
    [CSVPreferencesController setShowDeletedColumns:showHidden.on];
    [self.pageController refreshViewControllersData];
    [self synchUI];
}

- (IBAction) viewSelectionChanged:(id)sender
{
    [CSVPreferencesController setSelectedDetailsView:viewSelection.selectedSegmentIndex];
    [self.pageController refreshViewControllersData];
    [self synchUI];
}

- (IBAction) increaseSize:(id)sender
{
    [CSVPreferencesController increaseDetailsFontSize];
    [self.pageController refreshViewControllersData];
    [self synchUI];
}

- (IBAction) decreaseSize:(id)sender
{
    [CSVPreferencesController decreaseDetailsFontSize];
    [self.pageController refreshViewControllersData];
    [self synchUI];
}

- (IBAction) showImages:(id)sender
{
    [CSVPreferencesController setShowInlineImages:showImages.on];
    [self.pageController refreshViewControllersData];
    [self synchUI];
}

@end
