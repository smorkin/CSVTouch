//
//  CSV_TouchAppDelegate.m
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import "CSV_TouchAppDelegate.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "CSVFileParser.h"
#import "csv.h"
#import "FileDownloader.h"
#import "FilesViewController.h"
#import "FadeAnimator.h"
#import "CSVDataViewController.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"
#define FILE_PASSWORD @"filePassword"
#define INTERNAL_EXTENSION @".csvtouch"

#define HOW_TO_PAGES 7

@interface CSV_TouchAppDelegate ()
// For use when reading a CSV file list which includes
// pre-defined columns not to show
@property (nonatomic, strong) NSMutableDictionary *preDefinedHiddenColumns;
@property (nonatomic, assign) NSInteger httpStatusCode;
@property (nonatomic) NSMutableArray *URLsToDownload;
@property (nonatomic, assign) BOOL readingFileList;
@property (nonatomic, assign) BOOL downloadFailed;
@property BOOL refreshingAllFilesInProgress;
@property (nonatomic, retain) NSDate *enteredBackground;
@property (nonatomic, retain) NSMutableData *rawData;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSString *lastFileURL;
@end

@implementation CSV_TouchAppDelegate

static CSV_TouchAppDelegate *sharedInstance = nil;

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original
{
	return [original stringByAppendingString:INTERNAL_EXTENSION];
}
	
+ (CSV_TouchAppDelegate *) sharedInstance
{
	return sharedInstance;
}

+ (NSString *) manuallyAddedDocumentsPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

#define IMPORTED_CSV_FILES_FOLDER @"Imported files"

+ (NSString *) importedDocumentsPath
{
	NSString *path = [[self manuallyAddedDocumentsPath] stringByAppendingPathComponent:IMPORTED_CSV_FILES_FOLDER];
	BOOL isDirectory;
	if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path
								  withIntermediateDirectories:NO
												   attributes:nil
														error:NULL];
	}
	return path;
}

#define OTHER_APPS_IMPORTED_CSV_FILES_FOLDER @"Inbox"

+ (NSString *) otherAppsImportedDocumentsPath
{
	return [[self manuallyAddedDocumentsPath] stringByAppendingPathComponent:OTHER_APPS_IMPORTED_CSV_FILES_FOLDER];
}

- (void) readLocalFiles:(NSArray<NSURL *> *)urls
{
    for( NSURL *url in urls)
    {
        [self readRawFileData:[NSData dataWithContentsOfURL:url]
                     fileName:[url lastPathComponent]
              isLocalDownload:YES];
    }
}

#define LOCAL_MEDIA_DOCUMENTS_FOLDER @"Local media"

+ (NSString *) localMediaDocumentsPath
{
	NSString *path = [[self manuallyAddedDocumentsPath] stringByAppendingPathComponent:LOCAL_MEDIA_DOCUMENTS_FOLDER];
	BOOL isDirectory;
	if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path
								  withIntermediateDirectories:NO
												   attributes:nil
														error:NULL];
	}
	return path;
}

- (void) readRawFileData:(NSData *)data
				fileName:(NSString *)fileName
		 isLocalDownload:(BOOL)isLocalDownload
{
	if( [[CSVFileParser files] count] > 0 &&
	   ![CSVFileParser fileExistsWithURL:self.lastFileURL] &&
	   [CSVPreferencesController restrictedDataVersionRunning] )
	{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Only 1 file allowed"
                                                                       message:@"CSV Lite only allows 1 file; please delete the old one before downloading a new. Or buy CSV Touch :-)"
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:nil];
        [self.navigationController.topViewController presentViewController:alert
                                                                            animated:YES
                                                                          completion:nil];

	}
	else if( self.httpStatusCode >= 400&& !isLocalDownload )
	{
        // Mark the parser with fail to download
        CSVFileParser *fp = [CSVFileParser existingParserForName:fileName];
        if( fp )
        {
            fp.hasFailedToDownload = YES;
        }
        
		// Only show alert if we are not downloading multiple files
		if( [self.URLsToDownload count] == 0 )
		{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failure"
                                                                           message:[NSString httpStatusDescription:self.httpStatusCode]
                                                                     okButtonTitle:@"OK"
                                                                         okHandler:nil];
            [self.navigationController.topViewController presentViewController:alert
                                                                                animated:YES
                                                                              completion:nil];
		}
	}
	else
	{
        [CSVFileParser removeFileWithName:[CSV_TouchAppDelegate internalFileNameForOriginalFileName:fileName]];
        NSString *filePath = [[CSV_TouchAppDelegate importedDocumentsPath] stringByAppendingPathComponent:
                              [CSV_TouchAppDelegate internalFileNameForOriginalFileName:fileName]];
        CSVFileParser *fp = [CSVFileParser addParserWithRawData:data forFilePath:filePath];
		if( !isLocalDownload )
		{
			fp.URL = self.lastFileURL;
			if( [CSVPreferencesController hideAddress] )
				fp.hideAddress = TRUE;
		}
		else
		{
			fp.URL = @"";
		}
		fp.downloadDate = [NSDate date];
        fp.hasBeenDownloaded = TRUE;
		[fp saveToFile];
        fp.hiddenColumns = [self.preDefinedHiddenColumns objectForKey:fp.URL];
        [self.preDefinedHiddenColumns removeObjectForKey:fp.URL];
        [[FilesViewController sharedInstance].tableView reloadData];
	}
}

- (void) importManuallyAddedDocuments
{
	NSString *manuallyAddedDocumentsPath = [CSV_TouchAppDelegate manuallyAddedDocumentsPath];
    NSString *localMediaDocumentsPath = [CSV_TouchAppDelegate localMediaDocumentsPath];
	NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:manuallyAddedDocumentsPath
                                                                             error:NULL];
	for( NSString *fileName in documents )
	{
		if(![fileName hasPrefix:@"."] &&
		   ![fileName isEqualToString:IMPORTED_CSV_FILES_FOLDER] &&
		   ![fileName isEqualToString:OTHER_APPS_IMPORTED_CSV_FILES_FOLDER] &&
           ![fileName isEqualToString:LOCAL_MEDIA_DOCUMENTS_FOLDER])
		{
            // So either a manually added file which is a media file, or a regular csv file (hopefully)
            if( [fileName hasImageExtension] || [fileName hasMovieExtension] )
            {
                [[NSFileManager defaultManager] moveItemAtPath:[manuallyAddedDocumentsPath stringByAppendingPathComponent:fileName]
                                                        toPath:[localMediaDocumentsPath stringByAppendingPathComponent:fileName]
                                                         error:NULL];
            }
            else
            {
                [self readRawFileData:[NSData dataWithContentsOfFile:[manuallyAddedDocumentsPath stringByAppendingPathComponent:fileName]]
                             fileName:fileName
                      isLocalDownload:YES];
                [[NSFileManager defaultManager] removeItemAtPath:[manuallyAddedDocumentsPath stringByAppendingPathComponent:fileName] error:NULL];
            }
        }
	}
}

// Upgrading to new version where imported files are stored in a special directory, i.e.
// move all old files into the imported directory
- (BOOL) upgradeToStoringFilesInSpecialDirectory
{
	NSString *importedDocumentsPath = [CSV_TouchAppDelegate importedDocumentsPath];
	NSString *manuallyAddedDocumentsPath = [CSV_TouchAppDelegate manuallyAddedDocumentsPath];
    NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:manuallyAddedDocumentsPath
                                                                             error:NULL];
	
	for( NSString *fileName in documents )
	{
		if(![fileName hasPrefix:@"."] &&
		   [fileName hasSuffix:INTERNAL_EXTENSION])
		{
			if( [[NSFileManager defaultManager] moveItemAtPath:[manuallyAddedDocumentsPath stringByAppendingPathComponent:fileName]
														toPath:[importedDocumentsPath stringByAppendingPathComponent:fileName]
														 error:NULL] == FALSE )
				return FALSE;
		}
	}
    return TRUE;
}

- (void) loadOldDocuments
{
    [CSVFileParser removeAllFiles];
 	NSString *importedDocumentsPath = [CSV_TouchAppDelegate importedDocumentsPath];
	NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:importedDocumentsPath
                                                                             error:NULL];
	for( NSString *fileName in documents )
	{
		if(![fileName hasPrefix:@"."] &&
		   [fileName hasSuffix:INTERNAL_EXTENSION])
		{
            [CSVFileParser addParserWithRawData:nil forFilePath:[importedDocumentsPath stringByAppendingPathComponent:fileName]];
		}
	}
    [[FilesViewController sharedInstance].tableView reloadData];
}

- (void) importOtherAppsAddedDocuments
{
	NSString *otherAppsImportedDocumentsPath = [CSV_TouchAppDelegate otherAppsImportedDocumentsPath];
   	NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:otherAppsImportedDocumentsPath
																	error:NULL];
	for( NSString *fileName in documents )
	{
		if(![fileName hasPrefix:@"."])
		{
			[self readRawFileData:[NSData dataWithContentsOfFile:[otherAppsImportedDocumentsPath stringByAppendingPathComponent:fileName]]
						 fileName:fileName
				  isLocalDownload:YES];
			[[NSFileManager defaultManager] removeItemAtPath:[otherAppsImportedDocumentsPath stringByAppendingPathComponent:fileName] error:NULL];
		}
	}
 
}

- (void) loadLocalFiles
{
    if( ![self upgradeToStoringFilesInSpecialDirectory] )
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upgrade failed"
                                                                       message:@"Couldn't move files when upgrading! Please reinstall application and try again. Sorry!"
                                                                 okButtonTitle:@"Quit"
                                                                     okHandler:^(UIAlertAction *action) {
                                                                         exit(1);
                                                                     }];
        [self.navigationController.topViewController presentViewController:alert
                                                                            animated:YES
                                                                          completion:nil];
        return;
    }

    [self loadOldDocuments];    	
    [self importManuallyAddedDocuments];
    [self importOtherAppsAddedDocuments];
}

- (id)init
{
	if (self = [super init])
	{
		sharedInstance = self;
        self.URLsToDownload = [[NSMutableArray alloc] init];
        self.preDefinedHiddenColumns = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) scheduleAutomatedDownload
{
    [downloadTimer invalidate];
    NSDate *nextDownload = [CSVPreferencesController nextDownload];
    if( nextDownload )
    {
        // First let's schedule for next downloads
        downloadTimer = [[NSTimer alloc] initWithFireDate:nextDownload
                                                 interval:24*60*60
                                                   target:self
                                                 selector:@selector(downloadScheduled)
                                                 userInfo:nil
                                                  repeats:true];
        [[NSRunLoop currentRunLoop] addTimer:downloadTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void) setupTintColor
{
    UIColor *tint = [UIColor colorWithRed:0.60 green:0.13 blue:0.13 alpha:1.0];
    [[UIView appearance] setTintColor:tint];
    [[UIPageControl appearance] setPageIndicatorTintColor:[UIColor grayColor]];
    [[UIPageControl appearance] setCurrentPageIndicatorTintColor:tint];
    [[UISwitch appearance] setTintColor:tint];
    [[UISwitch appearance] setOnTintColor:tint];
    [[UISegmentedControl appearance] setTintColor:tint];
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self loadLocalFiles];
    [CSVPreferencesController applicationDidFinishLaunching];
    
    self.lastFileURL = [CSVPreferencesController lastUsedURL];
    if( !self.lastFileURL || [self.lastFileURL isEqualToString:@""] )
    {
        self.lastFileURL = @"http://";
    }
    
    [self scheduleAutomatedDownload];
    [self setupTintColor];
    
	return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	if( self.lastFileURL )
    {
        [CSVPreferencesController setLastUsedURL:self.lastFileURL];
    }
    
    [CSVFileParser saveColumnNames];
}

- (BOOL) downloadInProgress
{
    return self.connection != nil;
}

- (void) allDownloadsDone
{
    self.refreshingAllFilesInProgress = FALSE;
    [CSVPreferencesController setHideAddress:NO]; // In case we had temporarily set this from
    // a URL list file with preference settings
    [[FilesViewController sharedInstance] allDownloadsCompleted];
    [CSVFileParser resetClearingOfDownloadFlagsTimer];
    [[FilesViewController sharedInstance].tableView reloadData];
}

- (void) downloadDone
{
	self.connection = nil;
	// Are we in single file reload mode or all file reload mode?
	if( [self.URLsToDownload count] > 0 )
	{
		// Have to check if the file is a "local" one, i.e. without URL
		NSString *URL = [self.URLsToDownload objectAtIndex:0];
		if( [URL isEqualToString:@""] )
		{
			[self.URLsToDownload removeObjectAtIndex:0];
			[self downloadDone];
			return;
		}
		[self downloadFileWithString:URL];
		[self.URLsToDownload removeObjectAtIndex:0];
	}
	else 
	{
        [self allDownloadsDone];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.downloadFailed = true;
    self.readingFileList = FALSE;

    NSMutableString *alertTitle = [NSMutableString stringWithFormat:@"Download failure for %@", [[connection.currentRequest URL] description]];
	
	if( [self.URLsToDownload count] > 0 )
	{
        [alertTitle appendString:[NSString stringWithFormat:@"\n\nSkipping download of %lu remaining file%@. Error:",
                                  [self.URLsToDownload count],
                                  [self.URLsToDownload count] == 1 ? @"" : @"s"]];
		[self.URLsToDownload removeAllObjects];
	}
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:[error localizedDescription]
                                                             okButtonTitle:@"OK"
                                                                 okHandler:nil];
    [self.navigationController.topViewController presentViewController:alert
                                                          animated:YES
                                                        completion:nil];
	[self downloadDone];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
	[self.rawData appendData:newData];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if( [response isKindOfClass:[NSHTTPURLResponse class]] )
		self.httpStatusCode = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
 	// Are we downloading a file list?
	if( self.readingFileList )
	{
        [self fileListDownloadDone];
	}
	else
	{
		[self readRawFileData:self.rawData
					 fileName:[self.lastFileURL lastPathComponent]
			  isLocalDownload:NO];
	}
	self.rawData = nil;
	[self downloadDone];
}

- (void) fileListDownloadDone
{
    self.readingFileList = FALSE;
    [self.URLsToDownload removeAllObjects];
    
    // Check that we didn't get an http error
    if( self.httpStatusCode >= 400 )
    {
        self.downloadFailed = true;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failure for file list"
                                                                       message:[NSString httpStatusDescription:self.httpStatusCode]
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:nil];
        [self.navigationController.topViewController presentViewController:alert
                                                                  animated:YES
                                                                completion:nil];
        return;
    }
    
    NSString *s = [[NSString alloc] initWithData:self.rawData
                                        encoding:[CSVPreferencesController encoding]];
    NSUInteger length = [s length];
    NSUInteger lineStart, lineEnd, nextLineStart;
    NSRange lineRange;
    NSString *line;
    NSMutableArray *settings = [NSMutableArray array];
    BOOL readingSettings = FALSE;
    
    lineStart = lineEnd = nextLineStart = 0;
    while( nextLineStart < length )
    {
        [s getLineStart:&lineStart end:&nextLineStart
            contentsEnd:&lineEnd forRange:NSMakeRange(nextLineStart, 0)];
        lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
        line = [s substringWithRange:lineRange];
        if( !readingSettings && line && ![line isEqualToString:@""] )
        {
            NSArray *split = [line componentsSeparatedByString:@" "];
            if( [split count] == 2 ) // We have predefined hidden columns
            {
                NSString *fileName = [split objectAtIndex:0];
                [self.URLsToDownload addObject:fileName];
                split = [[split objectAtIndex:1] componentsSeparatedByString:@","];
                NSMutableIndexSet *hidden = [NSMutableIndexSet indexSet];
                for( NSString *n in split )
                {
                    [hidden addIndex:[n intValue]];
                }
                [self.preDefinedHiddenColumns setObject:hidden forKey:fileName];
            }
            else
            {
                [self.URLsToDownload addObject:line];
            }
        }
        else if( !readingSettings && line && [line isEqualToString:@""] )
            readingSettings = TRUE;
        else if( readingSettings && line && ![line isEqualToString:@""] )
            [settings addObject:line];
    }
    
    // We are doing the settings immediately, instead of later in [self downloadDone]
    // to avoid having to store the values somewhere locally
    if( [settings count] > 0 ){
        [CSVPreferencesController applySettings:settings];
    }
    
    // Now, remember the URLs in a non-volatile array since we will need those in case we are synchronising files.
    // Also, we need to store those we actually download during the downloads
    NSMutableSet *forRemoval = [NSMutableSet set];
    for( CSVFileParser *file in [CSVFileParser files])
    {
        if( ![self.URLsToDownload containsObject:file.URL] && !file.downloadedLocally)
        {
            [forRemoval addObject:file];
        }
    }
    for( CSVFileParser *file in forRemoval)
    {
        [CSVFileParser removeFile:file];
    }
}

- (void) startDownloadUsingURL:(NSURL *)url
{
    [[FilesViewController sharedInstance] fileDownloadsStarted];
	self.rawData = [[NSMutableData alloc] init];
    self.downloadFailed = false;
	self.httpStatusCode = 0;
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
											  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										  timeoutInterval:60];
	self.connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (!self.connection)
	{
        self.downloadFailed = true;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failure"
                                                                       message:@"Couldn't open connection"
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:nil];
        [self.navigationController.topViewController presentViewController:alert
                                                                            animated:YES
                                                                          completion:nil];
        [self downloadDone];
	}
}

- (void) loadFileList
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"URL file list address:"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[CSVPreferencesController lastUsedListURL] absoluteString];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action){
                                                   [self readFileListFromURL:alertController.textFields.firstObject.text];
                                               }];
    [alertController addAction:ok];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:cancel];
    
    [self.navigationController.visibleViewController presentViewController:alertController
                                                                  animated:YES
                                                                completion:nil];
}

- (void) loadNewFile
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"URL file address:"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.lastFileURL;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action){
                                                   [self downloadFileWithString:alertController.textFields.firstObject.text];
                                              }];
    [alertController addAction:ok];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:cancel];
    
    [self.navigationController.visibleViewController presentViewController:alertController
                                                                  animated:YES
                                                                completion:nil];
}

+ (NSCharacterSet *) tweakedURLPathAllowedCharacterSet
{
    NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
    [set formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
    [set addCharactersInString:@":"];
    return set;
}

- (void) readFileListFromURL:(NSString *)URLString
{    
	if( !URLString || [URLString isEqualToString:@""] )
		return;
    
    NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[CSV_TouchAppDelegate tweakedURLPathAllowedCharacterSet]]];
    
	self.readingFileList = TRUE;
	[self startDownloadUsingURL:URL];
	[CSVPreferencesController setLastUsedListURL:URL];
}

- (void) downloadFileWithString:(NSString *)URLString
{
	if( !URLString || [URLString isEqualToString:@""] )
		return;
	
    NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[CSV_TouchAppDelegate tweakedURLPathAllowedCharacterSet]]];
	[self startDownloadUsingURL:URL];
	
	self.lastFileURL = URLString;
}

- (void) startScheduledDownload
{
    if( [CSVPreferencesController synchronizeDownloadedFiles] &&
       [CSVPreferencesController canSynchronizeFiles])
    {
        [self readFileListFromURL:[[CSVPreferencesController lastUsedListURL] absoluteString]];
    }
    else
    {
        [self reloadAllFiles];
    }
}
    
- (void) downloadScheduled
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download scheduled"
                                                                   message:@"Time to reload all your files!"
                                                             okButtonTitle:@"Download"
                                                                 okHandler:^(UIAlertAction *action) {
                                                                     // Special thing here: Since this might pop up no matter where we are in the navigation controller, we must go back to files list view since otherwise we might crash (in case the file currently being inspected is reloaded)
                                                                     // Also, we shouldn't actually start reloading until we have popped back since otherwise UI will be a bit weird (resizing of navigationItem with large titles is a bit buggy), so we use CATransaction
                                                                     [CATransaction begin];
                                                                     [self.navigationController popToRootViewControllerAnimated:YES];
                                                                     [CATransaction setCompletionBlock:^{
                                                                         [self startScheduledDownload];
                                                                     }];
                                                                     [CATransaction commit];
                                                                 }
                                                         cancelButtonTitle:@"Cancel"
                                                             cancelHandler:nil];
    
    // Dismiss any presented view controllers, then show the alert
    if( self.navigationController.topViewController.presentedViewController != nil)
    {
        [self.navigationController.topViewController dismissViewControllerAnimated:NO completion:^{
            [self.navigationController.topViewController presentViewController:alert
                                                                      animated:YES
                                                                    completion:nil];

        }];
    }
    else
    {
        [self.navigationController.topViewController presentViewController:alert
                                                                  animated:YES
                                                                completion:nil];
    }
}

- (void) reloadAllFiles
{
    if( !self.refreshingAllFilesInProgress)
    {
        [CSVFileParser clearAllDownloadFlags];
        self.refreshingAllFilesInProgress = TRUE;
        [self.URLsToDownload removeAllObjects];
        for( CSVFileParser *fp in [CSVFileParser files] )
        {
            if( ![fp downloadedLocally])
            {
                [self.URLsToDownload addObject:[fp URL]];
            }
        }
        if( [self.URLsToDownload count] > 0 )
        {
            NSString *URL = [self.URLsToDownload objectAtIndex:0];
            [self downloadFileWithString:URL];
            [self.URLsToDownload removeObjectAtIndex:0];
        }
        [CSVPreferencesController setLastDownload:[NSDate date]];
    }
}

- (void) delayedURLOpen:(NSString *)s
{
    [self.navigationController popToRootViewControllerAnimated:NO];
	[self downloadFileWithString:s];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
	if( [[url scheme] isEqualToString:@"csvtouch"] )
	{
		[self performSelector:@selector(delayedURLOpen:)
				   withObject:[NSString stringWithFormat:@"http:%@", [url resourceSpecifier]]
				   afterDelay:0];
		return YES;
	}
	else if( [url isFileURL] )
	{		
		// First "download" the file
		[self readRawFileData:[NSData dataWithContentsOfFile:[url path]]
					 fileName:[[url path] lastPathComponent]
			  isLocalDownload:YES];
		[[NSFileManager defaultManager] removeItemAtPath:[url path] error:NULL];
		
		return YES;
	}
	
	return NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.enteredBackground = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Import any new files imported manually (e.g. in iTunes, while this app was in the background)
    [self importManuallyAddedDocuments];    
}

// Import any new files imported manually (e.g. in iTunes, while this app was running)
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self importManuallyAddedDocuments];
}

@end
