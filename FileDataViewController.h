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

// Weak, so if e.g. you download a new version of the file while this controller is open, you need to set the file again with the 'new' version of the file, and then call updateFileInfo to show the new data. You can use fileURL (which is strongly retained) to find the 'new' version by yourself.
@property (nonatomic, weak) CSVFileParser *file;
- (NSString *) fileURL;
- (void) updateFileInfo;

// Returns nil in case no controller is visible
+ (FileDataViewController *) currentInstance;

@end
