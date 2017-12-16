//
//  ParseErrorViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "ParseErrorViewController.h"

@interface ParseErrorViewController ()
{
    CSVFileParser *_file;
}

@end

@implementation ParseErrorViewController

- (void) setFile:(CSVFileParser *)file
{
    _file = file;
}

- (IBAction) toggleShowingRawString
{
    if( self.showRawString )
    {
        [[self textView] setText:[_file parseErrorString]];
    }
    else
    {
        [[self textView] setText:[NSString stringWithFormat:@"File read when using the selected encoding:\n\n%@", _file.rawString]];
    }
    self.showRawString = !self.showRawString;
}

@end
