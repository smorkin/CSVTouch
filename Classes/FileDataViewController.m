//
//  FileDataViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "FileDataViewController.h"
#import "CSV_TouchAppDelegate.h"
#import "FileDownloader.h"

@interface FileDataViewController ()
{
    CSVFileParser *file;
}

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
    fileEncodingSegment.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFileEncodings];
    newFileURL.clearButtonMode = UITextFieldViewModeWhileEditing;

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

- (void) configureForNewFile:(NSString *)defaultURL
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"1. For FTP download, use\n\n"];
    [s appendString:@"ftp://user:password@server.com/file.csv\n\n"];
    [s appendString:@"2. An example file to test the functionality is available at\n\n"];
    [s appendString:@"http://www.wigzell.net/csv/books.csv\n\n"];
    fileInfo.text = s;
    newFileURL.text = defaultURL;
}

- (void) updateFileInfo
{
    NSError *error;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self file] filePath] error:&error];
    
    if( fileAttributes )
    {
        NSMutableString *s = [NSMutableString string];
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [s appendFormat:@"Size: %.2f KB\n\n", ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
        if( [[self file] URL] && [[[self file] URL] isEqualToString:MANUALLY_ADDED_URL_VALUE] )
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
    if( [self file].hideAddress )
    {
        newFileURL.text = @"<address hidden>";
    }
    else
    {
        newFileURL.text = [self file].URL;
    }
    [self synchronizeFileEncoding];
}

- (void) setFile:(CSVFileParser *)newFile
{
    [file release];
    file = [newFile retain];
    [self updateFileInfo];
}

- (CSVFileParser *) file
{
    return file;
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if( textField == newFileURL )
    {
        [[CSV_TouchAppDelegate sharedInstance] performSelector:@selector(downloadFileWithString:) withObject:newFileURL.text afterDelay:0];
    }
    [textField endEditing:YES];
    return YES;
}

@end
