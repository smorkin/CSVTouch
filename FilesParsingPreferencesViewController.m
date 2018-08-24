//
//  FilesParsingPreferencesViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2018-02-26.
//

#import "FilesParsingPreferencesViewController.h"
#import "CSVPreferencesController.h"
#import "CSVFileParser.h"

@implementation FilesParsingPreferencesViewController

#define AUTO_DELIMITER @"<auto>"
#define TAB_DELIMITER @"<tab>"
#define SPACE_DELIMITER @"<space>"

- (void) viewWillAppear:(BOOL)animated
{
    alternativeParsing.onTintColor = [[UIView appearance] tintColor];
    keepQuotes.onTintColor = [[UIView appearance] tintColor];
    [super viewWillAppear:animated];
    [delimiterControl setTitle:AUTO_DELIMITER forSegmentAtIndex:0];
    [delimiterControl setTitle:@";" forSegmentAtIndex:1];
    [delimiterControl setTitle:@"," forSegmentAtIndex:2];
    [delimiterControl setTitle:@"." forSegmentAtIndex:3];
    [delimiterControl setTitle:@"|" forSegmentAtIndex:4];
    [delimiterControl setTitle:TAB_DELIMITER forSegmentAtIndex:5];
    [delimiterControl setTitle:SPACE_DELIMITER forSegmentAtIndex:6];
    [delimiterControl setWidth:20 forSegmentAtIndex:1];
    [delimiterControl setWidth:20 forSegmentAtIndex:2];
    [delimiterControl setWidth:20 forSegmentAtIndex:3];
    [delimiterControl setWidth:20 forSegmentAtIndex:4];
    [delimiterControl sizeToFit];
    [encodingControl setTitle:@"IsoLatin1" forSegmentAtIndex:0];
    [encodingControl setTitle:@"UTF8" forSegmentAtIndex:1];
    [encodingControl setTitle:@"Unicode" forSegmentAtIndex:2];
    [encodingControl setTitle:@"Mac" forSegmentAtIndex:3];
    [self synchUI];
}

- (void) synchUI
{
    alternativeParsing.on = [CSVPreferencesController useCorrectParsing];
    keepQuotes.on = [CSVPreferencesController keepQuotes];
    BOOL foundMatch = false;
    NSString *delimiter = [CSVPreferencesController delimiter];
    for( NSUInteger index = 0; index < delimiterControl.numberOfSegments; ++index){
        if( [[delimiterControl titleForSegmentAtIndex:index] isEqualToString:delimiter]){
            delimiterControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        else if( [[delimiterControl titleForSegmentAtIndex:index] isEqualToString:AUTO_DELIMITER] &&
                delimiter == nil){
            delimiterControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        else if( [[delimiterControl titleForSegmentAtIndex:index] isEqualToString:TAB_DELIMITER] &&
                [delimiter isEqualToString:@"\t"] ){
            delimiterControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        else if( [[delimiterControl titleForSegmentAtIndex:index] isEqualToString:SPACE_DELIMITER] &&
                [delimiter isEqualToString:@" "] ){
            delimiterControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
    }
    if( !foundMatch){
        delimiterControl.selectedSegmentIndex = 0;
    }
    foundMatch = NO;
    NSStringEncoding encoding = [CSVPreferencesController encoding];
    for( NSUInteger index = 0; index < encodingControl.numberOfSegments; ++index){
        if( [[encodingControl titleForSegmentAtIndex:index] isEqualToString:@"UTF8"] &&
           encoding == NSUTF8StringEncoding){
            encodingControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        else if( [[encodingControl titleForSegmentAtIndex:index] isEqualToString:@"Unicode"] &&
                encoding == NSUnicodeStringEncoding){
            encodingControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        else if( [[encodingControl titleForSegmentAtIndex:index] isEqualToString:@"Latin1"] &&
                encoding == NSISOLatin1StringEncoding){
            encodingControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
        if( [[encodingControl titleForSegmentAtIndex:index] isEqualToString:@"Mac"] &&
           encoding == NSMacOSRomanStringEncoding){
            encodingControl.selectedSegmentIndex = index;
            foundMatch = YES;
            break;
        }
    }
    if( !foundMatch){
        encodingControl.selectedSegmentIndex = 0;
    }
}

- (IBAction)somethingChanged:(id)sender
{
    if( sender == delimiterControl){
        NSString *title = [delimiterControl titleForSegmentAtIndex:delimiterControl.selectedSegmentIndex];
        if( [title isEqualToString:AUTO_DELIMITER] )
            [CSVPreferencesController setDelimiter:nil];
        else if( [title isEqualToString:TAB_DELIMITER] )
            [CSVPreferencesController setDelimiter:@"\t"];
        else if( [title isEqualToString:SPACE_DELIMITER] )
            [CSVPreferencesController setDelimiter:@" "];
        else
            [CSVPreferencesController setDelimiter:title];
    }
    else if( sender == encodingControl){
        NSString *title = [encodingControl titleForSegmentAtIndex:encodingControl.selectedSegmentIndex];
        if( [title isEqualToString:@"UTF8"] )
            [CSVPreferencesController setStringEncoding:NSUTF8StringEncoding];
        else if( [title isEqualToString:@"IsoLatin1"] )
            [CSVPreferencesController setStringEncoding:NSISOLatin1StringEncoding];
        else if( [title isEqualToString:@"Unicode"] )
            [CSVPreferencesController setStringEncoding:NSUnicodeStringEncoding];
        else if( [title isEqualToString:@"Mac"] )
            [CSVPreferencesController setStringEncoding:NSMacOSRomanStringEncoding];
    }
    else if( sender == keepQuotes){
        [CSVPreferencesController setKeepQuotes:keepQuotes.on];
    }
    else if( sender == alternativeParsing){
        [CSVPreferencesController setUseCorrectParsing:alternativeParsing.on];
    }
    // We need to reparse & save results
    [[CSVFileParser files] makeObjectsPerformSelector:@selector(encodingUpdated)];
    [CSVFileParser saveColumnNames];

    [self synchUI];
}

@end
