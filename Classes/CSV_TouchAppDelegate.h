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
	
	// Preferences
	// Data
	IBOutlet UISegmentedControl *encodingControl;
	IBOutlet UISwitch *smartDelimiterSwitch;
	IBOutlet UISegmentedControl *delimiterControl;
	// Appearance
	IBOutlet UISegmentedControl *sizeControl;
	// Sorting
	IBOutlet UISwitch *numericCompareSwitch;
	IBOutlet UISwitch *caseInsensitiveCompareSwitch;
	IBOutlet UITextField *maxNumberOfObjectsToSort;

	// Downloading a new file
	IBOutlet UIViewController *downloadNewFileController;
	IBOutlet UITextField *newFileURL;
	IBOutlet UIActivityIndicatorView *downloadActivityView;

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
- (IBAction) sizeControlChanged:(id)sender;
- (IBAction) delimiterControlChanged:(id)sender;
- (IBAction) encodingControlChanged:(id)sender;
- (IBAction) sortingChanged:(id)sender;
- (IBAction) refreshFile:(id)sender;

- (NSString *) delimiter;
- (NSInteger) tableViewSize;
- (NSStringEncoding) encoding;
- (BOOL) smartDelimiter;
- (NSUInteger) maxNumberOfObjectsToSort;

@end

extern NSUInteger sortingMask;
