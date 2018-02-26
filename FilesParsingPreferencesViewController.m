//
//  FilesParsingPreferencesViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-26.
//

#import "FilesParsingPreferencesViewController.h"
#import "CSVPreferencesController.h"

@implementation FilesParsingPreferencesViewController

- (void) viewWillAppear:(BOOL)animated
{
    alternativeParsing.onTintColor = [[UIView appearance] tintColor];
    keepQuotes.onTintColor = [[UIView appearance] tintColor];
    [super viewWillAppear:animated];
    [delimiterControl setTitle:@"auto" forSegmentAtIndex:0];
    [delimiterControl setTitle:@";" forSegmentAtIndex:1];
    [delimiterControl setTitle:@"," forSegmentAtIndex:2];
    [delimiterControl setTitle:@"." forSegmentAtIndex:3];
    [delimiterControl setTitle:@"|" forSegmentAtIndex:4];
    [delimiterControl setTitle:@"<tab>" forSegmentAtIndex:5];
    [delimiterControl setTitle:@"<space>" forSegmentAtIndex:6];
    [delimiterControl setWidth:20 forSegmentAtIndex:1];
    [delimiterControl setWidth:20 forSegmentAtIndex:2];
    [delimiterControl setWidth:20 forSegmentAtIndex:3];
    [delimiterControl setWidth:20 forSegmentAtIndex:4];
    [delimiterControl sizeToFit];
    [self synchUI];
}

- (void) synchUI
{
    alternativeParsing.on = [CSVPreferencesController useCorrectParsing];
    keepQuotes.on = [CSVPreferencesController keepQuotes];
    if( [CSVPreferencesController smartDelimiter])
    {
        delimiterControl.selectedSegmentIndex = 0;
    }
    else
    {
        NSString *delimiter = [CSVPreferencesController delimiter];
        BOOL foundMatch = false;
        for( NSUInteger index = 0; index < delimiterControl.numberOfSegments; ++index){
            if( [[delimiterControl titleForSegmentAtIndex:index] isEqualToString:delimiter]){
                delimiterControl.selectedSegmentIndex = index;
                foundMatch = YES;
                break;
            }
        }
        if( !foundMatch){
            delimiterControl.selectedSegmentIndex = 0;
        }
    }
}

- (IBAction)somethingChanged:(id)sender
{
//    if( sender == caseSensitiveSort){
//        [CSVPreferencesController setCaseSensitiveSort:caseSensitiveSort.on];
//    }
    [self synchUI];
}

@end
