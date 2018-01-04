//
//  FileDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "FileDataViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "FileDownloader.h"
#import "CSVPreferencesController.h"

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
    fileEncodingSegment.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFileEncodings];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if( self.file){
        [self updateFileInfo];
    }
}

- (void) synchronizeFileEncoding
{
    NSUInteger encoding = [CSVFileParser getEncodingSettingForFile:[[self file] fileName]];
    for( NSUInteger i = 0 ; i < [CSVFileParser allowedFileEncodings].count ; ++i)
    {
        if( [[[CSVFileParser allowedFileEncodings] objectAtIndex:i] integerValue] == encoding)
        {
            fileEncodingSegment.selectedSegmentIndex = i;
            return;
        }
    }
    fileEncodingSegment.selectedSegmentIndex = 0;
}

- (BOOL) fileRetrievedLocally
{
    return [[self file] URL] && [[[self file] URL] isEqualToString:MANUALLY_ADDED_URL_VALUE];
}

- (void) updateFileInfo
{
    NSMutableString *s = [NSMutableString string];
    if( ![self file].hideAddress ){
        [s appendFormat:@"Address: %@\n\n", ([self fileRetrievedLocally] ? @"<local import>" : self.file.URL)];
    }
    NSError *error;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self file] filePath] error:&error];
    
    if( fileAttributes )
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [s appendFormat:@"Size: %.2f KB\n\n",
         ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
        if( [self fileRetrievedLocally] )
            [s appendFormat:@"Imported: %@\n\n",
             ([self file].downloadDate ? [dateFormatter stringFromDate:[self file].downloadDate] : @"n/a")];
        else
            [s appendFormat:@"Downloaded: %@\n\n",
             ([self file].downloadDate ? [dateFormatter stringFromDate:[self file].downloadDate] : @"Available after next download")];
        [s appendFormat:@"File: %@\n\n", [self file].filePath];
        fileInfo.text = s;
    }
    else
    {
        fileInfo.text = [error localizedDescription];
    }
    [self synchronizeFileEncoding];
}

- (IBAction) segmentClicked:(id)sender
{
    NSUInteger oldEncoding = [CSVFileParser getEncodingSettingForFile:[self file].fileName];
    NSStringEncoding newEncoding = [[[CSVFileParser allowedFileEncodings] objectAtIndex:fileEncodingSegment.selectedSegmentIndex] integerValue];
    
    if( oldEncoding != newEncoding)
    {
        if( newEncoding == DEFAULT_ENCODING )
        {
            [CSVFileParser removeFileEncodingForFile:[self file].fileName];
        }
        else
        {
            [CSVFileParser setFileEncoding:newEncoding
                                   forFile:[self file].fileName];
        }
        [[self file] encodingUpdated];
    }
}

@end
