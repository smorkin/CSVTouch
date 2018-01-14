//
//  ItemPreferenceController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-01-14.
//

#import "ItemPreferenceController.h"
#import "CSVPreferencesController.h"

@interface ItemPreferenceController ()

@end

@implementation ItemPreferenceController

- (void) viewWillAppear:(BOOL)animated
{
    showHidden.onTintColor = self.pageController.navigationController.navigationBar.tintColor;
    [self synchUI];
    [super viewWillAppear:animated];
}

- (void) synchUI
{
    showHidden.on = [CSVPreferencesController showDeletedColumns];
    viewSelection.selectedSegmentIndex = [CSVPreferencesController selectedDetailsView];
}

- (void) showHiddenChanged:(id)sender
{
    [CSVPreferencesController setShowDeletedColumns:showHidden.on];
    [self.pageController refreshViewControllers];
    [self synchUI];
}

- (void) viewSelectionChanged:(id)sender
{
    [CSVPreferencesController setSelectedDetailsView:viewSelection.selectedSegmentIndex];
    [self.pageController refreshViewControllers];
    [self synchUI];
}

@end
