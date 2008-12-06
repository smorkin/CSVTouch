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
	IBOutlet UISwitch *fileProtection;
	IBOutlet UILabel *fileProtectionLabel;
	
	// "Advanced" password interaction
	IBOutlet OzyRotatableViewController *passwordController;
	IBOutlet UINavigationBar *newPasswordNavigationBar;
	IBOutlet UITextField *newPassword1;
	IBOutlet UITextField *newPassword2;

	// For better GUI when things are slow...
	IBOutlet UIView *activityView;
	IBOutlet UIActivityIndicatorView *fileParsingActivityView;
	
	NSURLConnection *connection;
    NSMutableData *rawData;
	
	NSInteger _httpStatusCode;
	
	CSVFileParser *_fileInspected;
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (NSArray *) allowedDelimiters;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic, retain) CSVFileParser *fileInspected;

- (IBAction) downloadNewFile:(id)sender;
- (IBAction) doDownloadNewFile:(id)sender;
- (IBAction) cancelDownloadNewFile:(id)sender;
- (IBAction) fileProtectionChanged;
- (IBAction) newPasswordDone;
- (IBAction) changePassword;

- (void) checkPassword;
- (BOOL) hasCheckedPassword;


- (void) downloadFileWithString:(NSString *)URL;
- (void) showFileInfo:(CSVFileParser *)fp;

- (void) slowActivityStarted;
- (void) slowActivityCompleted;

@end
