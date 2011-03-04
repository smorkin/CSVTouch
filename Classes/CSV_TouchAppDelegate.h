//
//  CSV_TouchAppDelegate.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"

@class OzyRotatableViewController, CSVFileParser, CSVDataViewController;

// Enum for alert view tags
enum{PASSWORD_CHECK = 1,
	PASSWORD_SET,
	UPGRADE_FAILED,
	CSV_FILE_LIST_SETUP,
	RELOAD_FILES};


@interface CSV_TouchAppDelegate : NSObject <UIApplicationDelegate,
UITabBarControllerDelegate,
OzymandiasApplicationDelegate> {
	
	// Main view
	IBOutlet UIWindow *window;
	IBOutlet CSVDataViewController *dataController;
	
	// Startup
	IBOutlet OzyRotatableViewController *startupController;
	IBOutlet UIActivityIndicatorView *startupActivityView;
	
	// File information / Downloading new file
	IBOutlet OzyRotatableViewController *fileViewController;
	IBOutlet UITextField *newFileURL;
	IBOutlet UITextView *fileInfo;
	IBOutlet UIToolbar *downloadToolbar;
	
	// For better GUI when things are slow...
	IBOutlet UIView *activityView;
	IBOutlet UIActivityIndicatorView *fileParsingActivityView;
	
	NSURLConnection *connection;
    NSMutableData *rawData;
	
	NSInteger _httpStatusCode;
	
	CSVFileParser *_fileInspected;

	NSMutableArray *_URLsToDownload;
	BOOL _readingFileList;
		
	NSTimer *downloadTimer;
	
	NSDate *_enteredBackground;
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (NSArray *) allowedDelimiters;
+ (BOOL) iPadMode;

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic, retain) CSVFileParser *fileInspected;
@property (nonatomic, readonly) NSMutableArray *URLsToDownload;
@property (nonatomic, assign) BOOL readingFileList;
@property (nonatomic, retain) NSDate *enteredBackground;


- (IBAction) downloadNewFile:(id)sender;
- (IBAction) doDownloadNewFile:(id)sender;
- (IBAction) cancelDownloadNewFile:(id)sender;

- (void) downloadFileWithString:(NSString *)URL;
- (void) reloadAllFiles;
- (void) showFileInfo:(CSVFileParser *)fp;
- (void) loadFileList;

- (void) slowActivityStarted;
- (void) slowActivityCompleted;

@end
