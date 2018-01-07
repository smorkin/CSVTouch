//
//  FileDataViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import "CSVFileParser.h"

@interface FileDataViewController : UIViewController <UITextViewDelegate>
{
    IBOutlet UITextView *fileInfo;
    IBOutlet UISegmentedControl *fileEncodingSegment;
}

- (IBAction) segmentClicked:(id)sender;
- (IBAction) exportFile:(id)sender;

@property (nonatomic, weak) CSVFileParser *file;

@end
