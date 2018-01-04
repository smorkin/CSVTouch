//
//  FileDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "CSVFileParser.h"

@interface FileDataViewController : UIViewController <UITextViewDelegate, UIDocumentPickerDelegate>
{
    IBOutlet UITextView *fileInfo;
    IBOutlet UISegmentedControl *fileEncodingSegment;
}

- (IBAction) segmentClicked:(id)sender;
- (IBAction) exportFile;

@property (nonatomic, weak) CSVFileParser *file;

@end
