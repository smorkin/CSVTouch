//
//  ItemsAppearancePreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-25.
//

#import "ItemsAppearancePreferencesController.h"
#import "CSVPreferencesController.h"
#import "ItemsViewController.h"
#import "CSVFileParser.h"
#import "CSVRow.h"

@interface ItemsAppearancePreferencesController ()

@end

@implementation ItemsAppearancePreferencesController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self synchUI];
}

- (void) synchUI
{
    groupItems.on = [CSVPreferencesController useGroupingForItems];
    groupNumbers.on = [CSVPreferencesController groupNumbers];
    monospaced.on = [CSVPreferencesController useMonospacedFont];
    useWordSeparator.on = ![CSVPreferencesController blankWordSeparator];
    fixedWidthAlternative.selectedSegmentIndex = [CSVPreferencesController fixedWidthsAlternative];
    multiLinte.on = [CSVPreferencesController multilineItemCells];
    
    groupNumbers.enabled = [CSVPreferencesController useGroupingForItems];
    fixedWidthAlternative.enabled = [CSVPreferencesController useMonospacedFont];
    fixedWidthAlternativeLabel.enabled = [CSVPreferencesController useMonospacedFont];
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
    else if( sender == monospaced)
    {
        [CSVPreferencesController setUseMonospacedFont:monospaced.on];
        [CSVFileParser fixedWidthSettingsChangedUsingUI];
    }
    else if( sender == useWordSeparator)
    {
        [CSVPreferencesController setBlankWordSeparator:!useWordSeparator.on];
    }
    else if( sender == fixedWidthAlternative)
    {
        [CSVPreferencesController setFixedWidthsAlternative:(FixedWidthAlternative)fixedWidthAlternative.selectedSegmentIndex];
        [CSVFileParser fixedWidthSettingsChangedUsingUI];
    }
    else if( sender == multiLinte)
    {
        [CSVPreferencesController setMultilineItemCells:multiLinte.on];
    }
    [CSVRow refreshRowFormatStrings];
    [[ItemsViewController sharedInstance] refresh];
    [self synchUI];
}
@end
