//
//  CSV_TouchAppDelegate.m
//  CSV Touch
//
//  Created by Simon Wigzell on 21/05/2008.
//  Copyright Ozymandias 2008. All rights reserved.
//

#import "CSV_TouchAppDelegate.h"
#import "OzyTableViewController.h"
#import "OzyRotatableViewController.h"
#import "CSVDataViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "CSVFileParser.h"
#import "csv.h"
#import "FileDownloader.h"
#import "FilesViewController.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"
#define FILE_PASSWORD @"filePassword"
#define INTERNAL_EXTENSION @".csvtouch"

#define HOW_TO_PAGES 7

@interface CSV_TouchAppDelegate ()
// For use when reading a CSV file list which includes
// pre-defined columns not to show
@property (nonatomic, strong) NSMutableDictionary *preDefinedHiddenColumns;
@end

@implementation CSV_TouchAppDelegate

static CSV_TouchAppDelegate *sharedInstance = nil;

+ (NSArray *) allowedDelimiters
{
	static NSArray *delimiters = nil;
	
	if( !delimiters )
		delimiters = [NSArray arrayWithObjects:@",", @";", @".", @"|", @" ", @"\t", nil];
	
	return delimiters;
}

+ (BOOL) iPadMode
{
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original
{
	return [original stringByAppendingString:INTERNAL_EXTENSION];
}
	

static NSString *newPassword = nil;

- (NSString *) currentPasswordHash
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:FILE_PASSWORD];
}

- (void) checkPassword
{
    NSString *query = [CSVPreferencesController usePassword] ? @"Input password:" : @"Remove password:";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:query
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = TRUE;
        textField.placeholder = @"Password";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action){
                                                   NSString *input = alertController.textFields.firstObject.text;
                                                   if( [[input ozyHash] isEqual:[[NSUserDefaults standardUserDefaults] dataForKey:FILE_PASSWORD]] )
                                                   {
                                                       if( [CSVPreferencesController usePassword] == NO )
                                                       {
                                                           [[NSUserDefaults standardUserDefaults] removeObjectForKey:FILE_PASSWORD];
                                                       }
                                                   }
                                                   else
                                                   {
                                                       [self performSelector:@selector(checkPassword)
                                                                  withObject:nil
                                                                  afterDelay:0.3];
                                                   }
                                               }];
    [alertController addAction:ok];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action){
                                                       exit(1);
                                                   }];
    [alertController addAction:cancel];
    [[self dataController].topViewController presentViewController:alertController
                                                                        animated:YES
                                                                      completion:nil];
}

- (void) setPassword:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = TRUE;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action){
                                                   NSString *input = alertController.textFields.firstObject.text;
                                                   if( newPassword == nil )
                                                   {
                                                       newPassword = [input copy];
                                                       [self performSelector:@selector(setPassword:)
                                                                  withObject:@"Confirm Password"
                                                                  afterDelay:0.3];
                                                   }
                                                   else if( [input isEqual:newPassword] )
                                                   {
                                                       [[NSUserDefaults standardUserDefaults] setObject:[newPassword ozyHash] forKey:FILE_PASSWORD];
                                                       newPassword = nil;
                                                   }
                                                   else
                                                   {
                                                       newPassword = nil;
                                                       [self performSelector:@selector(setPassword:)
                                                                  withObject:@"Passwords Don't Match!\nSet Password"
                                                                  afterDelay:0.3];
                                                   }
                                               }];
    [alertController addAction:ok];
    [[self dataController].topViewController presentViewController:alertController
                                                                        animated:YES
                                                                      completion:nil];
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
        [[self dataController].topViewController presentViewController:alert
                                                                            animated:YES
                                                                          completion:nil];

	}
	else if( self.httpStatusCode >= 400&& !isLocalDownload )
	{
		// Only show alert if we are not downloading multiple files
		if( [self.URLsToDownload count] == 0 )
		{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failuer"
                                                                           message:[NSString httpStatusDescription:self.httpStatusCode]
                                                                     okButtonTitle:@"OK"
                                                                         okHandler:nil];
            [[self dataController].topViewController presentViewController:alert
                                                                                animated:YES
                                                                              completion:nil];
		}
	}
	else
	{
        [CSVFileParser removeFileWithName:[CSV_TouchAppDelegate internalFileNameForOriginalFileName:fileName]];
        NSString *filePath = [[CSV_TouchAppDelegate importedDocumentsPath] stringByAppendingPathComponent:
                              [CSV_TouchAppDelegate internalFileNameForOriginalFileName:fileName]];
		CSVFileParser *fp = [[CSVFileParser alloc] initWithRawData:data filePath:filePath];
		if( !isLocalDownload )
		{
			fp.URL = self.lastFileURL;
			if( [CSVPreferencesController hideAddress] )
				fp.hideAddress = TRUE;
		}
		else
		{
			fp.URL = MANUALLY_ADDED_URL_VALUE;
		}
		fp.downloadDate = [NSDate date];
        fp.hasBeenDownloaded = TRUE;
		[fp saveToFile];
        fp.hiddenColumns = [self.preDefinedHiddenColumns objectForKey:fp.URL];
        [self.preDefinedHiddenColumns removeObjectForKey:fp.URL];
        [[FilesViewController sharedInstance] dataLoaded];
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
 	NSString *importedDocumentsPath = [CSV_TouchAppDelegate importedDocumentsPath];
    NSMutableArray *files = [NSMutableArray array];
	NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:importedDocumentsPath
                                                                             error:NULL];
	for( NSString *fileName in documents )
	{
		if(![fileName hasPrefix:@"."] &&
		   [fileName hasSuffix:INTERNAL_EXTENSION])
		{
			CSVFileParser *fp = [CSVFileParser parserWithFile:[importedDocumentsPath stringByAppendingPathComponent:fileName]];
			[files addObject:fp];
		}
	}
    [[FilesViewController sharedInstance] dataLoaded];
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
        [[self dataController].topViewController presentViewController:alert
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
		_URLsToDownload = [[NSMutableArray alloc] init];
		_filesAddedThroughURLList = [[NSMutableArray alloc] init];
        self.preDefinedHiddenColumns = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self loadLocalFiles];
    [CSVPreferencesController applicationDidFinishLaunching];
    [[self dataController] applicationDidFinishLaunchingInEmergencyMode:[CSVPreferencesController safeStart]];
    
    self.lastFileURL = [CSVPreferencesController lastUsedURL];
    if( !self.lastFileURL || [self.lastFileURL isEqualToString:@""] )
    {
        self.lastFileURL = @"http://";
    }
    
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
        // Now let's check if we need to do a new download immediately
        NSDate *lastDownload = [CSVPreferencesController lastDownload];
        if( !lastDownload ||
           ( lastDownload && [nextDownload timeIntervalSinceDate:lastDownload] > 24*60*60 ))
        {
            [self performSelector:@selector(downloadScheduled)
                       withObject:nil
                       afterDelay:2.0];
        }
    }
    
    if( [self currentPasswordHash] != nil )
    {
        [self checkPassword];
    }
    else if( [CSVPreferencesController usePassword] )
    {
        [self setPassword:@"New Password"];
    }
    else
    {
        // Show the Add file window in case no files are present
        if( [[CSVFileParser files] count] == 0 )//&& ![CSVPreferencesController hasShownHowTo])
        {
            self.introHowToController = [[IntroViewController alloc] init];
            [self.introHowToController startHowToShowing:self];
        }
    }

	return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	if( self.lastFileURL )
    {
        [CSVPreferencesController setLastUsedURL:self.lastFileURL];
    }
	[[self dataController] applicationWillTerminate];
}

- (void) downloadDone
{
	self.connection = nil;
	// Are we in single file reload mode or all file reload mode?
	if( [self.URLsToDownload count] > 0 )
	{
		// Have to check if the file is a "local" one, i.e. without URL
		NSString *URL = [self.URLsToDownload objectAtIndex:0];
		if( [URL isEqualToString:MANUALLY_ADDED_URL_VALUE] )
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
		if([CSVPreferencesController synchronizeDownloadedFiles])
		{
            // Only continue if download was successful; cf. Mark McCorkle's mail of 2012-04-18
            if( self.downloadFailed == false )
            {
                // We need to remove any files not included amongst the newly downloaded ones
                NSMutableSet *newFileNames = [NSMutableSet set];
                NSMutableSet *oldFileNames = [NSMutableSet set];
                for( NSString *URLString in self.filesAddedThroughURLList )
                {
                    [newFileNames addObject:[CSV_TouchAppDelegate internalFileNameForOriginalFileName:[URLString lastPathComponent]]];
                }
                for( CSVFileParser *file in [CSVFileParser files] )
                {
                    [oldFileNames addObject:[file fileName]];
                }
                [oldFileNames minusSet:newFileNames];
                for( NSString *name in oldFileNames )
                {
                    [CSVFileParser removeFileWithName:name];
                    [[NSFileManager defaultManager] removeItemAtPath:[[CSV_TouchAppDelegate importedDocumentsPath] stringByAppendingPathComponent:name] error:NULL];
                }
            }
		}
		[CSVPreferencesController setHideAddress:NO]; // In case we had temporarily set this from
													  // a URL list file with preference settings
        [[self dataController] dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.downloadFailed = true;
    
	NSString *alertTitle;
	
	if( self.readingFileList )
		self.readingFileList = FALSE;
	
	if( [self.URLsToDownload count] > 0 )
	{
		alertTitle = @"Download failure; no more files will be downloaded";
		[self.URLsToDownload removeAllObjects];
	}
	else
    {
		alertTitle = @"Download Failure";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:[error localizedDescription]
                                                             okButtonTitle:@"OK"
                                                                 okHandler:nil];
    [[self dataController].topViewController presentViewController:alert
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
		self.readingFileList = FALSE;
		[self.URLsToDownload removeAllObjects];
		[self.filesAddedThroughURLList removeAllObjects];
        
        // Check that we didn't get an http error
        if( self.httpStatusCode >= 400 )
        {
            self.downloadFailed = true;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failure"
                                                                           message:[NSString httpStatusDescription:self.httpStatusCode]
                                                                     okButtonTitle:@"OK"
                                                                         okHandler:nil];
            [[self dataController].topViewController presentViewController:alert
                                                                               animated:YES
                                                                             completion:nil];
            [self downloadDone];
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
		
		// Take a copy of the files to download,
		// to use later in case synchronizeDownloadedFiles is used
		[self.filesAddedThroughURLList addObjectsFromArray:self.URLsToDownload];
		
		// We are doing the settings immediately, instead of later in [self downloadDone]
		// to avoid having to store the values somewhere locally
		if( [settings count] > 0 )
			[CSVPreferencesController applySettings:settings]; 
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

- (void) addNewFile
{
    [self.fileViewController configureForNewFile];
	[self.dataController pushViewController:self.fileViewController animated:YES];
}

- (void) showFileInfo:(CSVFileParser *)fp
{
    [self.fileViewController setFile:fp];
    [self.dataController pushViewController:self.fileViewController
                                        animated:YES];
}

- (void) startDownloadUsingURL:(NSURL *)url
{
	self.rawData = [[NSMutableData alloc] init];
    self.downloadFailed = false;
	self.httpStatusCode = 0;
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
											  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										  timeoutInterval:300.0];
	self.connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (!self.connection)
	{
        self.downloadFailed = true;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download failure"
                                                                       message:@"Couldn't open connection"
                                                                 okButtonTitle:@"OK"
                                                                     okHandler:nil];
        [[self dataController].topViewController presentViewController:alert
                                                                            animated:YES
                                                                          completion:nil];
        [self downloadDone];
	}
}

- (void) loadFileList
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"File list address:"
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
    
    [[self dataController].visibleViewController presentViewController:alertController
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
	if( !URLString || [URLString isEqualToString:MANUALLY_ADDED_URL_VALUE] )
		return;
	
    NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[CSV_TouchAppDelegate tweakedURLPathAllowedCharacterSet]]];
	[self startDownloadUsingURL:URL];
	
	// Update this in case you want to download a file from a similar URL later on
	self.lastFileURL = URLString;
}

- (void) downloadScheduled
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download scheduled"
                                                                   message:@"Time to reload all your files!"
                                                             okButtonTitle:@"Download"
                                                                 okHandler:^(UIAlertAction *action) {
                                                                     [self reloadAllFiles];
                                                                 }
                                                         cancelButtonTitle:@"Cancel"
                                                             cancelHandler:nil];
    [[self dataController].topViewController presentViewController:alert
                                                                        animated:YES
                                                                      completion:nil];
}

- (void) reloadAllFiles
{
	if( [CSVPreferencesController simpleMode] && [CSVPreferencesController lastUsedListURL] )
	{
		NSURL *url = [CSVPreferencesController lastUsedListURL];
		[self readFileListFromURL:[url absoluteString]];
	}
	else
	{
		[self.URLsToDownload removeAllObjects];
		for( CSVFileParser *fp in [CSVFileParser files] )
		{
			if( [fp URL] && ![[fp URL] isEqualToString:MANUALLY_ADDED_URL_VALUE] )
				[self.URLsToDownload addObject:[fp URL]];
		}
		if( [self.URLsToDownload count] > 0 )
		{
			NSString *URL = [self.URLsToDownload objectAtIndex:0];
			[self downloadFileWithString:URL];
			[self.URLsToDownload removeObjectAtIndex:0];
		}
	}
	[CSVPreferencesController setLastDownload:[NSDate date]];
}

- (void) delayedURLOpen:(NSString *)s
{
	[self downloadFileWithString:s];
	[[self dataController] popToRootViewControllerAnimated:NO];
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

- (void) slowActivityStarted
{
	activityView.frame = [[UIScreen mainScreen] bounds];
	[self.window addSubview:activityView];
	[fileParsingActivityView startAnimating];
}

- (void) slowActivityCompleted
{
	if( [fileParsingActivityView isAnimating] )
	{
		[fileParsingActivityView stopAnimating];
		[activityView removeFromSuperview];
	}
}	

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.enteredBackground = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	long maxMinutesInBackground = [CSVPreferencesController maxSafeBackgroundMinutes];
	if(maxMinutesInBackground != NSIntegerMax &&
	   self.enteredBackground &&
	   [[NSDate date] timeIntervalSinceDate:self.enteredBackground] > maxMinutesInBackground*60 )
	{
		[self performSelector:@selector(checkPassword)
				   withObject:nil 
				   afterDelay:0.3];
	}
    // Import any new files imported manually (e.g. in iTunes, while this app was in the background)
    [self importManuallyAddedDocuments];
    
    if( [CSVPreferencesController defaultsHaveChanged])
    {
        [self loadOldDocuments];
        [[self dataController] popToViewController:[FilesViewController sharedInstance] animated:NO];
        [CSVPreferencesController resetDefaultsHaveChanges];
    }
}

// Import any new files imported manually (e.g. in iTunes, while this app was running)
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self importManuallyAddedDocuments];
}

@end

@implementation CSV_TouchAppDelegate (IntroProtocol)

- (void) dismissHowToController:(IntroViewController *)controller
{
    if( self.introHowToController == controller)
    {
        [CSVPreferencesController setHasShownHowTo];
        self.window.rootViewController = [self dataController];
    }
}

@end

@implementation CSV_TouchAppDelegate (FileEncoding)

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

@end

