//
//  CSV_TouchAppDelegate.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"
#import "IntroViewController.h"
#import "FileDataViewController.h"

@class OzyRotatableViewController, CSVFileParser, CSVDataViewController;

@interface CSV_TouchAppDelegate : NSObject <UIApplicationDelegate,
OzymandiasApplicationDelegate>
{
	// For better GUI when things are slow...
	IBOutlet UIView *activityView;
	IBOutlet UIActivityIndicatorView *fileParsingActivityView;
    
	NSTimer *downloadTimer;
    
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (NSArray *) allowedDelimiters;
+ (BOOL) iPadMode;

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original;
+ (NSString *) localMediaDocumentsPath;

// Presenting a How-To at first ever start
@property (nonatomic, retain) IntroViewController *introHowToController;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic, readonly) NSMutableArray *URLsToDownload;
@property (nonatomic, retain) NSMutableArray *filesAddedThroughURLList;
@property (nonatomic, assign) BOOL readingFileList;
@property (nonatomic, assign) BOOL downloadFailed;
@property (nonatomic, retain) NSDate *enteredBackground;
@property (nonatomic, retain) NSMutableData *rawData;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSString *lastFileURL;
@property (nonatomic, weak) CSVDataViewController *dataController;
@property (nonatomic, weak) FileDataViewController *fileViewController;

- (void) addNewFile;
- (void) downloadFileWithString:(NSString *)URL;
- (void) reloadAllFiles;
- (void) showFileInfo:(CSVFileParser *)fp;
- (void) loadFileList;

@end

@interface CSV_TouchAppDelegate (IntroProtocol)
<IntroViewControllerDelegate>
@end

@interface CSV_TouchAppDelegate (FileEncoding)
@end

