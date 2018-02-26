//
//  ItemsAppearancePreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-25.
//

#import "ItemsAppearancePreferencesController.h"
#import "CSVPreferencesController.h"
#import "ItemsViewController.h"
#import "CSVRow.h"

@interface ItemsAppearancePreferencesController ()

@end

@implementation ItemsAppearancePreferencesController

- (void) viewWillAppear:(BOOL)animated
{
    groupItems.onTintColor = [[UIView appearance] tintColor];
    groupNumbers.onTintColor = [[UIView appearance] tintColor];
    fixedWidth.onTintColor = [[UIView appearance] tintColor];
    useWordSeparator.onTintColor = [[UIView appearance] tintColor];
    predefinedWidths.onTintColor = [[UIView appearance] tintColor];
    [super viewWillAppear:animated];
    [self synchUI];
}

- (void) synchUI
{
    groupItems.on = [CSVPreferencesController useGroupingForItems];
    groupNumbers.on = [CSVPreferencesController groupNumbers];
    fixedWidth.on = [CSVPreferencesController useFixedWidth];
    useWordSeparator.on = ![CSVPreferencesController blankWordSeparator];
    predefinedWidths.on = [CSVPreferencesController definedFixedWidths];
    
    groupNumbers.enabled = [CSVPreferencesController useGroupingForItems];
    predefinedWidths.enabled = [CSVPreferencesController useFixedWidth];
}

- (IBAction)switchChanged:(id)sender
{
    if( sender == groupItems){
        [CSVPreferencesController setUseGroupingForItems:groupItems.on];
    }
    else if( sender == groupNumbers)
    {
        [CSVPreferencesController setGroupNumbers:groupNumbers.on];
    }
    else if( sender == fixedWidth)
    {
        [CSVPreferencesController setUseFixedWidth:fixedWidth.on];
    }
    else if( sender == useWordSeparator)
    {
        [CSVPreferencesController setBlankWordSeparator:!useWordSeparator.on];
    }
    else if( sender == predefinedWidths)
    {
        [CSVPreferencesController setDefinedFixedWidths:predefinedWidths.on];
    }
    [CSVRow refreshRowFormatStrings];
    [[ItemsViewController sharedInstance] refresh];
    [self synchUI];
}
@end
