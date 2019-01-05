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

@interface FileDataViewController()
@property (nonatomic, strong) NSString *URLForFile;
@end

@implementation FileDataViewController

static FileDataViewController *_currentFileDataViewControllerInstance;

+ (FileDataViewController *) currentInstance
{
    return _currentFileDataViewControllerInstance;
}

- (void) setFile:(CSVFileParser *)file
{
    _file = file;
    self.URLForFile = file.URL;
}

- (NSString *) fileURL
{
    return self.URLForFile;
}

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

- (void)viewDidLoad
{
    [self configureFileEncodings];
    [super viewDidLoad];

}

- (void) viewWillAppear:(BOOL)animated
{
    _currentFileDataViewControllerInstance = self;
    [self updateFileInfo];
    self.title = self.file.tableViewDescription;
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    _currentFileDataViewControllerInstance = nil;
    [super viewWillDisappear:animated];
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

- (void) updateFileInfo
{
    NSMutableString *s = [NSMutableString string];
    if( ![self file].hideAddress ){
        if( [self.file downloadedLocally])
        {
            [s appendString:@"Imported from: <local import>\n\n"];
        }
        else
        {
            [s appendFormat:@"Imported from: %@\n(click to re-download & to copy address)\n\n", self.file.URL];
        }
    }
    NSError *error;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self file] filePath] error:&error];
    
    if( fileAttributes )
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        if( [self.file downloadedLocally] )
            [s appendFormat:@"Imported: %@\n\n",
             ([self file].downloadDate ? [dateFormatter stringFromDate:[self file].downloadDate] : @"n/a")];
        else
            [s appendFormat:@"Imported: %@\n\n",
             ([self file].downloadDate ? [dateFormatter stringFromDate:[self file].downloadDate] : @"Available after next download")];
        [s appendFormat:@"Size: %.2f KB\n\n",
         ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
//        [s appendFormat:@"Internal data file: %@\n\n", [self file].filePath];
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    // Do not use the actual URL we get here since it might have "wrong" string encodings etc. Instead use the URL stored in the actual file parser
    NSString *s = self.file.URL;
    if( s ) // E.g. locally downloaded files have no URL
    {
        [[CSV_TouchAppDelegate sharedInstance] downloadFileWithString:s];
        [[UIPasteboard generalPasteboard] setString:s];
    }
    return NO;
}

- (IBAction)exportFile:(id)sender;
{
    NSURL *url = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    url = [url URLByAppendingPathComponent:[self.file.fileName stringByDeletingPathExtension]]; // We have custom extension
    if( url && [self.file.fileRawData writeToURL:url atomically:YES])
    {
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
        controller.modalPresentationStyle = UIModalPresentationPopover;
        controller.popoverPresentationController.permittedArrowDirections =
        UIPopoverArrowDirectionDown;
        UIView *v = (UIView *)sender;
        controller.popoverPresentationController.sourceView = v;
        CGRect anchorRect = CGRectMake(v.frame.size.width/2, 0, 1, 1);
        controller.popoverPresentationController.sourceRect = anchorRect;
        [self presentViewController:controller animated:YES completion:nil];
    }
}

@end
