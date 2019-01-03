//
//  ItemsSortAndSearchPreferencesController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-25.
//

#import "ItemsSortAndSearchPreferencesController.h"
#import "CSVPreferencesController.h"
#import "ItemsViewController.h"

@interface ItemsSortAndSearchPreferencesController ()

@end

@implementation ItemsSortAndSearchPreferencesController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self synchUI];
}

- (void) synchUI
{
    caseSensitiveSort.on = [CSVPreferencesController caseSensitiveSort];
    numericSort.on = [CSVPreferencesController numericSort];
    literalSort.on = [CSVPreferencesController literalSort];
    correctSort.on = [CSVPreferencesController correctSort];
    smartSearchClearing.on = [CSVPreferencesController smartSeachClearing];
    
}

- (IBAction)switchChanged:(id)sender
{
    if( sender == caseSensitiveSort){
        [ItemsViewController sharedInstance].needsSort = YES;
        [CSVPreferencesController setCaseSensitiveSort:caseSensitiveSort.on];
    }
    else if( sender == numericSort)
    {
        [ItemsViewController sharedInstance].needsSort = YES;
        [CSVPreferencesController setNumericSort:numericSort.on];
    }
    else if( sender == literalSort)
    {
        [ItemsViewController sharedInstance].needsSort = YES;
        [CSVPreferencesController setLiteralSort:literalSort.on];
    }
    else if( sender == correctSort)
    {
        [ItemsViewController sharedInstance].needsSort = YES;
        [CSVPreferencesController setCorrectSort:correctSort.on];
    }
    else if( sender == smartSearchClearing)
    {
        [CSVPreferencesController setSmartSearchClearing:smartSearchClearing.on];
    }
    [[ItemsViewController sharedInstance] refresh];
    [self synchUI];
}
@end
