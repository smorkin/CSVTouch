//
//  CSV_TouchAppDelegate.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OzyRotatableViewController;

@interface CSV_TouchAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
	
	// Main view
	IBOutlet UIWindow *window;
	IBOutlet UITabBarController *tabBarController;
	
	// Startup
	IBOutlet OzyRotatableViewController *startupController;
	IBOutlet UIActivityIndicatorView *startupActivityView;
	
	// Downloading a new file
	IBOutlet UIViewController *downloadNewFileController;
	IBOutlet UITextField *newFileURL;
	IBOutlet UIActivityIndicatorView *downloadActivityView;

	NSURLConnection *connection;
    NSMutableData *rawData;
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (NSArray *) allowedDelimiters;
+ (BOOL) allowRotation;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;

//- (IBAction) prefsDone:(id)sender;

- (IBAction) downloadNewFile:(id)sender;
- (IBAction) doDownloadNewFile:(id)sender;
- (IBAction) cancelDownloadNewFile:(id)sender;
- (IBAction) refreshFile:(id)sender;

@end
