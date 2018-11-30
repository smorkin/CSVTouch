//
//  CSV_TouchAppDelegate.h
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"
#import "FileDataViewController.h"

@interface CSV_TouchAppDelegate : NSObject <UIApplicationDelegate,
OzymandiasApplicationDelegate>
{
	NSTimer *downloadTimer;
}

+ (CSV_TouchAppDelegate *) sharedInstance;
+ (BOOL) iPadMode;

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original;
+ (NSString *) localMediaDocumentsPath;

// Presenting a How-To at first ever start
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic, readonly) NSMutableArray *URLsToDownload;
@property (nonatomic, assign) BOOL readingFileList;
@property (nonatomic, assign) BOOL downloadFailed;
@property (nonatomic, retain) NSDate *enteredBackground;
@property (nonatomic, retain) NSMutableData *rawData;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSString *lastFileURL;
@property (nonatomic, retain) UINavigationController *navigationController;

- (void) downloadFileWithString:(NSString *)URL;
- (void) reloadAllFiles;
- (void) loadFileList;
- (void) loadNewFile;
- (void) readLocalFiles:(NSArray<NSURL *> *)urls;
- (void) scheduleAutomatedDownload;

@end
