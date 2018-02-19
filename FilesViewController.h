//
//  FilesViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-16.
//

#import <UIKit/UIKit.h>
#import "CSVFileParser.h"

@interface FilesViewController : UITableViewController <UIPopoverPresentationControllerDelegate, UIDocumentPickerDelegate>

+ (instancetype) sharedInstance;

// We have custom transition so want a custom "back" button (since we are not sliding in the view
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue;

- (void) addFileUsingURL;
- (void) addFileUsingURLList;
- (void) importLocalFile;

// Call after files have been refreshed
- (void) allFilesRefreshed;

@end

