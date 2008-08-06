//
//  CSV_TouchAppDelegate.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"

@class OzyRotatableViewController, OzyRotatableTabBarController, CSVFileParser;

@interface CSV_TouchAppDelegate : NSObject <UIApplicationDelegate,
UITabBarControllerDelegate,
OzymandiasApplicationDelegate> {
	
	// Main view
	IBOutlet UIWindow *window;
	IBOutlet OzyRotatableTabBarController *tabBarController;
	
	// Startup
	IBOutlet OzyRotatableViewController *startupController;
	IBOutlet UIActivityIndicatorView *startupActivityView;
	
	// Downloading a new file
	IBOutlet UIViewController *downloadNewFileController;
	IBOutlet UITextField *newFileURL;
	IBOutlet UIActivityIndicatorView *downloadActivityView;
	IBOutlet UIToolbar *downloadToolbar;

	// For better GUI when things are slow...
	IBOutlet UIView *activityView;
	IBOutlet UIActivityIndicatorView *fileParsingActivityView;
	
	NSURLConnection *connection;
    NSMutableData *rawData;
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (NSArray *) allowedDelimiters;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;

//- (IBAction) prefsDone:(id)sender;

- (IBAction) downloadNewFile:(id)sender;
- (IBAction) doDownloadNewFile:(id)sender;
- (IBAction) cancelDownloadNewFile:(id)sender;

- (void) downloadFileWithString:(NSString *)URL;

- (void) slowActivityStartedInViewController:(UIViewController *)viewController;
- (void) slowActivityCompleted;

@end
