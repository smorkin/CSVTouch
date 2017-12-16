//
//  FileDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "FileDataViewController.h"
#import "CSV_TouchAppDelegate.h"

@interface FileDataViewController ()

@end

@implementation FileDataViewController

- (void) configureFileEncodings
{
    [fileEncodingSegment removeAllSegments];
    for( NSUInteger i = 0 ; i < [CSVFileParser allowedFileEncodingNames].count ; ++i)
    {
        [fileEncodingSegment insertSegmentWithTitle:[[CSVFileParser allowedFileEncodingNames] objectAtIndex:i]
                                            atIndex:i
                                           animated:NO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFileEncodings];
}

@end
