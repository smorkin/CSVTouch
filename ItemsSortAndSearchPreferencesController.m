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
    caseSensitiveSort.onTintColor = [[UIView appearance] tintColor];
    numericSort.onTintColor = [[UIView appearance] tintColor];
    literalSort.onTintColor = [[UIView appearance] tintColor];
    correctSort.onTintColor = [[UIView appearance] tintColor];
    smartSearchClearing.onTintColor = [[UIView appearance] tintColor];
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
        [CSVPreferencesController setCaseSensitiveSort:caseSensitiveSort.on];
    }
    else if( sender == numericSort)
    {
        [CSVPreferencesController setNumericSort:numericSort.on];
    }
    else if( sender == literalSort)
    {
        [CSVPreferencesController setLiteralSort:literalSort.on];
    }
    else if( sender == correctSort)
    {
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
