//
//  FileDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "OzyRotatableViewController.h"
#import "CSVFileParser.h"

@interface FileDataViewController : OzyRotatableViewController
{
    IBOutlet UITextField *newFileURL;
    IBOutlet UITextView *fileInfo;
    IBOutlet UISegmentedControl *fileEncodingSegment;
}

- (IBAction) segmentClicked:(id)sender;

// For viewing data about existing file
- (CSVFileParser *) file;
- (void) setFile:(CSVFileParser *)file;

// For downloading a new file
- (void) configureForNewFile:(NSString *)defaultURL;

@end
