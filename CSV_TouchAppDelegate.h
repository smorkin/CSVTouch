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

@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) UIWindow *window;

+ (CSV_TouchAppDelegate *) sharedInstance;

+ (NSString *) localMediaDocumentsPath;

- (void) downloadFileWithString:(NSString *)URL;
- (void) reloadAllFiles;
- (void) loadFileList;
- (void) loadNewFile;
- (void) readLocalFiles:(NSArray<NSURL *> *)urls;
- (void) scheduleAutomatedDownload;

- (BOOL) downloadInProgress;

@end
