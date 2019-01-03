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
    multiLine.on = [CSVPreferencesController multilineItemCells];
    
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
        [ItemsViewController sharedInstance].needsResetShortDescriptions = YES;
        [CSVPreferencesController setUseMonospacedFont:monospaced.on];
        [CSVFileParser fixedWidthSettingsChangedUsingUI];
    }
    else if( sender == useWordSeparator)
    {
        [ItemsViewController sharedInstance].needsResetShortDescriptions = YES;
        [CSVPreferencesController setBlankWordSeparator:!useWordSeparator.on];
    }
    else if( sender == fixedWidthAlternative)
    {
        [ItemsViewController sharedInstance].needsResetShortDescriptions = YES;
        [CSVPreferencesController setFixedWidthsAlternative:(FixedWidthAlternative)fixedWidthAlternative.selectedSegmentIndex];
        [CSVFileParser fixedWidthSettingsChangedUsingUI];
    }
    else if( sender == multiLine)
    {
        [CSVPreferencesController setMultilineItemCells:multiLine.on];
    }
    [CSVRow refreshRowFormatStrings];
    [[ItemsViewController sharedInstance] refresh];
    [self synchUI];
}
@end
