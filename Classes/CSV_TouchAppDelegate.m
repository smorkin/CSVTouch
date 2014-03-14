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
//#import "OzyRotatableTabBarController.h"
#import "CSVDataViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "CSVFileParser.h"
#import "csv.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"
#define FILE_PASSWORD @"filePassword"
#define MANUALLY_ADDED_URL_VALUE @""
#define INTERNAL_EXTENSION @".csvtouch"

#define HOW_TO_PAGES 7

@implementation CSV_TouchAppDelegate

@synthesize window;
@synthesize httpStatusCode = _httpStatusCode;
@synthesize fileInspected = _fileInspected;
@synthesize URLsToDownload = _URLsToDownload;
@synthesize filesAddedThroughURLList = _filesAddedThroughURLList;
@synthesize readingFileList = _readingFileList;
@synthesize downloadFailed = _downloadFailed;
@synthesize enteredBackground = _enteredBackground;
@synthesize downloadToolbar;

static CSV_TouchAppDelegate *sharedInstance = nil;

+ (NSArray *) allowedDelimiters
{
	static NSArray *delimiters = nil;
	
	if( !delimiters )
		delimiters = [[NSArray arrayWithObjects:@",", @";", @".", @"|", @" ", @"\t", nil] retain];
	
	return delimiters;
}

+ (BOOL) iPadMode
{
	return [[[UIDevice currentDevice] name] hasSubstring:@"iPad"];
}

+ (NSString *) internalFileNameForOriginalFileName:(NSString *)original
{
	return [original stringByAppendingString:INTERNAL_EXTENSION];
}
	

- (CSVDataViewController *) dataController
{
	return dataController;
}

static NSString *newPassword = nil;

- (NSString *) currentPasswordHash
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:FILE_PASSWORD];
}

- (void) checkPassword
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Input password:"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Quit"
                                          otherButtonTitles:@"OK", nil];

    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
	alert.tag = PASSWORD_CHECK;
	[alert show];
	[alert release];
}

- (void) setPassword:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
	[alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeDefault;
	alert.tag = PASSWORD_SET;
	[alert show];
	[alert release];
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
	if( [[self dataController] numberOfFiles] > 0 &&
	   ![[self dataController] fileExistsWithURL:[newFileURL text]] &&
	   [CSVPreferencesController restrictedDataVersionRunning] )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Only 1 file allowed"
														message:@"CSV Lite only allows 1 file; please delete the old one before downloading a new. Or buy CSV Touch :-)"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
	else if( self.httpStatusCode >= 400&& !isLocalDownload )
	{
		// Only show alert if we are not downloading multiple files
		if( [self.URLsToDownload count] == 0 )
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download Failure"
															 message:[NSString httpStatusDescription:self.httpStatusCode]
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];	
			[alert show];
		}
	}
	else
	{
		CSVFileParser *fp = [[CSVFileParser alloc] initWithRawData:data];
		fp.filePath = [[CSV_TouchAppDelegate importedDocumentsPath] stringByAppendingPathComponent:
					   [CSV_TouchAppDelegate internalFileNameForOriginalFileName:fileName]];
		if( !isLocalDownload )
		{
			fp.URL = [newFileURL text];
			if( [CSVPreferencesController hideAddress] )
				fp.hideAddress = TRUE;
		}
		else
		{
			fp.URL = MANUALLY_ADDED_URL_VALUE;
		}
		fp.downloadDate = [NSDate date];
		[fp saveToFile];
		[[self dataController] newFileDownloaded:fp];
		[fp release];
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
	[[self dataController] setFiles:files];
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
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Upgrade failed"
														 message:@"Couldn't move files when upgrading! Please reinstall application and try again." 
														delegate:self
											   cancelButtonTitle:@"Quit"
											   otherButtonTitles:nil] autorelease];
		alert.tag = UPGRADE_FAILED;
		[alert show];
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
        _howToControllers = [[NSMutableArray alloc] init];
	}
	return self;
}

#define NEW_FILE_URL @"newFileURL"

- (void) delayedStartup
{
	[self loadLocalFiles];
	[CSVPreferencesController applicationDidFinishLaunching];
	[[self dataController] applicationDidFinishLaunchingInEmergencyMode:[CSVPreferencesController safeStart]];
	
	NSString *savedNewFileURL = [[NSUserDefaults standardUserDefaults] objectForKey:NEW_FILE_URL];
	if( savedNewFileURL && ![savedNewFileURL isEqualToString:@""] )
		newFileURL.text = savedNewFileURL;
	else
		newFileURL.text = @"http://";
	newFileURL.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	// Configure and show the window
	[startupActivityView stopAnimating];
	[startupController.view removeFromSuperview];
	
//    [[self window] setTintColor:[UIColor redColor]];
	[self.window addSubview:[[self dataController] view]];
	[self.window makeKeyAndVisible];
    
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
    
    // Fix position of download file-window
    CGRect frame = self.downloadToolbar.frame;
    frame.origin.y += 20;
    self.downloadToolbar.frame = frame;
    frame = newFileURL.frame;
    frame.origin.y += 20;
    newFileURL.frame = frame;
    frame = fileInfo.frame;
    frame.origin.y += 20;
    fileInfo.frame = frame;

	
	// Show the Add file window in case no files are present
	if( [[self dataController] numberOfFiles] == 0 && ![CSVPreferencesController hasShownHowTo])
	{
        [self startHowToShowing];
	}
}

- (void) awakeFromNib
{
	if( [CSV_TouchAppDelegate iPadMode] )
		[[NSBundle mainBundle] loadNibNamed:@"iPadMainWindow" owner:self options:nil];
	else 
		[[NSBundle mainBundle] loadNibNamed:@"iPhoneMainWindow" owner:self options:nil];
}

//UIApplicationLaunchOptionsURLKey

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{	
	startupController.view.frame = [[UIScreen mainScreen] applicationFrame];
	[self.window addSubview:startupController.view];
    [self.window setRootViewController:startupController];
	[startupActivityView startAnimating];
	
	// Only show startup activity view if there are files cached
	NSString *documentsPath = [CSV_TouchAppDelegate importedDocumentsPath];
	if( documentsPath && [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath
																			  error:NULL] count] > 0 )
	{
		[self.window makeKeyAndVisible];
	}
	if( [self currentPasswordHash] != nil )
	{
		[self performSelector:@selector(checkPassword) withObject:nil afterDelay:0];
	}
	else if( [CSVPreferencesController usePassword] )
	{
		[self performSelector:@selector(setPassword:) withObject:@"New Password" afterDelay:0];
	}	
	else
	{
		[self performSelector:@selector(delayedStartup) withObject:nil afterDelay:0];
	}
	return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	if( newFileURL.text )
		[[NSUserDefaults standardUserDefaults] setObject:newFileURL.text
												  forKey:NEW_FILE_URL];
	[[self dataController] applicationWillTerminate];
}

- (void)dealloc {
	[self.window release];
	[rawData release];
	[self.URLsToDownload release];
	[self.filesAddedThroughURLList release];
    [_howToControllers release];
	[super dealloc];
}



- (void) downloadDone
{
	[connection release];
	connection = nil;
	[self slowActivityCompleted];
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
                for( CSVFileParser *file in [dataController files] )
                {
                    [oldFileNames addObject:[file fileName]];
                }
                [oldFileNames minusSet:newFileNames];
                for( NSString *name in oldFileNames )
                {
                    [dataController removeFileWithName:name];
                    [[NSFileManager defaultManager] removeItemAtPath:[[CSV_TouchAppDelegate importedDocumentsPath] stringByAppendingPathComponent:name] error:NULL];
                }
            }
		}
		[CSVPreferencesController setHideAddress:NO]; // In case we had temporarily set this from
													  // a URL list file with preference settings
		[newFileURL resignFirstResponder];
		self.fileInspected = nil;
		[[self dataController] dismissModalViewControllerAnimated:YES];
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
		alertTitle = @"Download Failure";
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:alertTitle
													 message:[error localizedDescription]
													delegate:self
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil] autorelease];
	[alert show];
	[self downloadDone];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
	[rawData appendData:newData];
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
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download Failure"
                                                             message:[NSString httpStatusDescription:self.httpStatusCode]
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];	
            [alert show];
            [self downloadDone];
        }
        
		NSString *s = [[NSString alloc] initWithData:rawData 
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
					for( NSString *s in split )
						[hidden addIndex:[s intValue]];
					[[CSVDataViewController sharedInstance] setHiddenColumns:hidden
																	 forFile:[CSV_TouchAppDelegate internalFileNameForOriginalFileName:
																			  [fileName lastPathComponent]]];
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
		[self readRawFileData:rawData
					 fileName:[[newFileURL text] lastPathComponent]
			  isLocalDownload:NO];
	}
	[rawData release];
	rawData = nil;
	[self downloadDone];
}

- (IBAction) downloadNewFile:(id)sender
{
	NSMutableString *s = [NSMutableString string];
	[s appendString:@"1. For FTP download, use\n\n"];
	[s appendString:@"ftp://user:password@server.com/file.csv\n\n"];
	[s appendString:@"2. An example file to test the functionality is available at\n\n"];
	[s appendString:@"http://www.wigzell.net/csv/books.csv\n\n"];
	fileInfo.text = s;
	[[self dataController] presentModalViewController:fileViewController animated:YES];
}

- (void) showFileInfo:(CSVFileParser *)fp
{
	self.fileInspected = fp;
	
	NSError *error;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fp filePath] error:&error];
	
	if( fileAttributes )
	{
		NSMutableString *s = [NSMutableString string];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[s appendFormat:@"Size: %.2f KB\n\n", ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
		if( [fp URL] && [[fp URL] isEqualToString:MANUALLY_ADDED_URL_VALUE] )
			[s appendFormat:@"Imported: %@\n\n", 
			 (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"n/a")];
		else
			[s appendFormat:@"Downloaded: %@\n\n", 
			 (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"Available after next download")];
		[s appendFormat:@"File: %@\n\n", fp.filePath];
		fileInfo.text = s;
	}
	else
	{
		fileInfo.text = [error localizedDescription];
	}
	if( fp.hideAddress )
		newFileURL.text = @"<address hidden>";
	else 
		newFileURL.text = fp.URL;
	[[self dataController] presentModalViewController:fileViewController animated:YES];
}


- (void) startDownloadUsingURL:(NSURL *)url
{
	[rawData release];
	rawData = [[NSMutableData alloc] init];
    self.downloadFailed = false;
	self.httpStatusCode = 0;
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
											  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										  timeoutInterval:300.0];
	connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (!connection)
	{
        self.downloadFailed = true;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Failure"
														message:@"Couldn't open connection"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[self downloadDone];
	}
}

// This is when the user presses the "Download" button (the icon with the map) or presses "Enter" on keyboard
- (IBAction) doDownloadNewFile:(id)sender
{
	[newFileURL endEditing:YES];
	[self slowActivityStarted];
	[self startDownloadUsingURL:[NSURL URLWithString:[[newFileURL text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (IBAction) cancelDownloadNewFile:(id)sender
{
	[self downloadDone];
}

- (void) loadFileList
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File list address:" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;    
	[alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
	[alert textFieldAtIndex:0].secureTextEntry = NO;
    if( [CSVPreferencesController lastUsedListURL] )
        [alert textFieldAtIndex:0].text = [[CSVPreferencesController lastUsedListURL] absoluteString];
	alert.tag = CSV_FILE_LIST_SETUP;
	[alert show];
	[alert release];	
}

- (void) readFileListFromURL:(NSString *)URLString
{    
	if( !URLString || [URLString isEqualToString:@""] )
		return;
	
	NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	self.readingFileList = TRUE;
	[self slowActivityStarted];
	[self startDownloadUsingURL:URL];
	[CSVPreferencesController setLastUsedListURL:URL];
}

- (void) downloadFileWithString:(NSString *)URL
{
	if( !URL || [URL isEqualToString:MANUALLY_ADDED_URL_VALUE] )
		return;
	
	[self slowActivityStarted];
	[self startDownloadUsingURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	// Update this in case you want to download a file from a similar URL later on
	newFileURL.text = URL;
}

- (void) downloadScheduled
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download scheduled"
													message:@"Time to reload all your files!"
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Download" ,nil] autorelease];
	alert.tag = RELOAD_FILES;
	[alert show];
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
		for( CSVFileParser *fp in [[CSVDataViewController sharedInstance] files] )
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if( textField == newFileURL )
	{
		[self performSelector:@selector(doDownloadNewFile:) withObject:self afterDelay:0];
	}
	[textField endEditing:YES];
	return YES;
}

- (void) delayedURLOpen:(NSString *)s
{
	[self downloadFileWithString:s];
	[[self dataController] popToRootViewControllerAnimated:NO];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
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
	activityView.frame = [[UIScreen mainScreen] applicationFrame];
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
}

// Import any new files imported manually (e.g. in iTunes, while this app was running)
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self importManuallyAddedDocuments];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *text = @"";
    if( actionSheet.alertViewStyle == UIAlertViewStylePlainTextInput ||
       actionSheet.alertViewStyle == UIAlertViewStyleSecureTextInput)
        text = [actionSheet textFieldAtIndex:0].text;
	if(actionSheet.tag == PASSWORD_CHECK)
	{
		if(buttonIndex > 0)
		{
			if( [[text ozyHash] isEqual:[[NSUserDefaults standardUserDefaults] dataForKey:FILE_PASSWORD]] )
			{
				if( [CSVPreferencesController usePassword] == NO )
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:FILE_PASSWORD];
				if( !self.enteredBackground ) // If entered background, the password check is not at startup
					[self performSelector:@selector(delayedStartup)
							   withObject:nil
							   afterDelay:0.3];
			}
			else
			{
				[self performSelector:@selector(checkPassword)
						   withObject:nil
						   afterDelay:0.3];
			}
		}
		else // Cancel button pressed
		{
			exit(1);
		}
	}
	else if(actionSheet.tag == PASSWORD_SET)
	{
		if(buttonIndex > 0)
		{
			if( newPassword == nil )
			{
				newPassword = [text copy];
				[self performSelector:@selector(setPassword:)
						   withObject:@"Confirm Password"
						   afterDelay:0.3];
			}
			else if( [text isEqual:newPassword] )
			{
				[[NSUserDefaults standardUserDefaults] setObject:[newPassword ozyHash] forKey:FILE_PASSWORD];
				[newPassword release];
				newPassword = nil;
				[self performSelector:@selector(delayedStartup) withObject:nil afterDelay:0];
			}
			else
			{
				[newPassword release];
				newPassword = nil;
				[self performSelector:@selector(setPassword:)
						   withObject:@"Passwords Don't Match!\nSet Password"
						   afterDelay:0.3];
			}
		}
		else // Cancel button pressed
		{
			[CSVPreferencesController clearSetPassword];
			[self performSelector:@selector(delayedStartup) withObject:nil afterDelay:0];
		}
	}
	else if( actionSheet.tag == CSV_FILE_LIST_SETUP )
	{
		[self readFileListFromURL:text];
	}
	else if( actionSheet.tag == UPGRADE_FAILED )
	{
		exit(1);
	}
	else if( actionSheet.tag == RELOAD_FILES && buttonIndex > 0)
	{
		[self reloadAllFiles];
	}
}

// PageViewController data source
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

- (void) startHowToShowing
{
    if( self.howToPageController == nil )
    {
        UIToolbar *bar = [[[UIToolbar alloc] init] autorelease];
        bar.delegate = self;
        [bar setBackgroundImage:[UIImage new]
             forToolbarPosition:UIBarPositionAny
                     barMetrics:UIBarMetricsDefault];
        [bar setShadowImage:[UIImage new]
         forToolbarPosition:UIToolbarPositionAny];
        self.howToPageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        self.howToPageController.dataSource = self;
        self.howToPageController.view.backgroundColor = [UIColor colorWithRed:0.917 green:0.917 blue:0.945 alpha:1];
        [self.howToPageController.view addSubview:bar];
        [bar sizeToFit];
        CGRect frame = bar.frame;
        frame.origin.y += 20;
        bar.frame = frame;
        UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(dismissHowToController)] autorelease];
        bar.items = [NSArray arrayWithObject:button];
        [self setupHowToControllers];
        
        HowToController *initialViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
        [self.howToPageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    self.window.rootViewController = self.howToPageController;
}

- (void) setupHowToControllers
{
    for( int i = 0; i < HOW_TO_PAGES; ++i)
    {
        HowToController *childViewController = [[[HowToController alloc] initWithNibName:@"HowToController" bundle:nil] autorelease];
        childViewController.index = i;
        childViewController.delegate = self;
        CGRect rect = self.window.rootViewController.view.frame;
        childViewController.view.frame = rect;
        [_howToControllers addObject:childViewController];
    }
}

- (HowToController *)viewControllerAtIndex:(NSUInteger)index {
    return [_howToControllers objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [(HowToController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [(HowToController *)viewController index];
    
    
    index++;
    
    if (index == HOW_TO_PAGES) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return HOW_TO_PAGES;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

- (void)dismissHowToController
{
    [CSVPreferencesController setHasShownHowTo];
    self.window.rootViewController = [self dataController];
}

- (NSString *)titleForHowTo:(NSInteger)index
{
    switch(index)
    {
        case 0:
            return NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
        case 1:
            return @"Dropbox, Google Drive etc";
        case 2:
            return @"Mail, messages etc";
        case 3:
            return @"iTunes";
        case 4:
            return @"Direct internet access";
        case 5:
            return @"Advanced";
        case 6:
            return @"Troubleshooting";
        default:
            return @"";
    }
}

- (NSString *)textForHowTo:(NSInteger)index
{
    NSString *appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    switch(index)
    {
        case 0:
        {
            NSMutableString *s = [NSMutableString stringWithString:@"Welcome! To get started, you first need to get your CSV file(s) into the app. There are multiple ways of doing this, presented on the following pages."];
            if( [CSVPreferencesController restrictedDataVersionRunning])
            {
                [s appendString:@"\n\nNOTE: This free version is restricted to 1 file and only shows the 150 first items."];
            }
            return s;
        }
        case 1:
            return [NSString stringWithFormat:@"By adding your file to any cloud drive which has an app for iOS, you can simply go to that app and select to open the CSV file in %@.", appName];
        case 2:
            return @"Similarly, you can select to open a CSV file which has been sent to you by mail or messaging apps which allow you to send files.";
        case 3:
            return [NSString stringWithFormat:@"If you connect your device to iTunes, you can add CSV files directly in iTunes in the same way you add files to any app: Select the device, select the Apps tab, and scroll down until you see %@. Then you add the files there.", appName];
        case 4:
            return [NSString stringWithFormat:@"If your file is accessibly directly from internet, you can select the \"+\" button in %@ and then input the address to your file. See http://www.ozymandias.se for more details about how to use this feature.", appName];
        case 5:
            return [NSString stringWithFormat:@"Finally, there are some more unusual ways of getting your files into %@. See the full documentation at http://www.ozymandias.se.", appName];
        case 6:
            return @"If you are having problems, please check the full documentation at http://www.ozymandias.se; if that still doesn't help, you can always mail me (email address available in the AppStore) :-)";
        default:
            return @"";
    }
}

- (NSAttributedString *) stringForController:(HowToController *)controller
{
    NSMutableAttributedString *s = [[[NSMutableAttributedString alloc] init] autorelease];
    NSString *title = [self titleForHowTo:controller.index];
    NSString *text = [self textForHowTo:controller.index];
    [s.mutableString appendString:title];
    [s.mutableString appendString:@"\n\n"];
    [s.mutableString appendString:text];

    //add alignments for title
    NSMutableParagraphStyle *centeredParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [centeredParagraphStyle setAlignment:NSTextAlignmentCenter];
    [s addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:NSMakeRange(0, title.length)];
    //add alignment for text
    NSMutableParagraphStyle *normalParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [normalParagraphStyle setAlignment:NSTextAlignmentNatural];
    [s addAttribute:NSParagraphStyleAttributeName value:normalParagraphStyle range:NSMakeRange(title.length, text.length+2)];
    
    //add larger font for title
    UIFont *font = [controller.howToText.font fontWithSize:20];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, title.length)];

    return s;
}

- (UIImage *) imageForController:(HowToController *)controller
{
    switch(controller.index)
    {
        case 1:
            return [UIImage imageNamed:@"file_via_app.png"];
        case 2:
            return [UIImage imageNamed:@"file_via_mail.png"];
        case 3:
            return [UIImage imageNamed:@"file_via_itunes.png"];
        case 4:
            return [UIImage imageNamed:@"file_via_internet.png"];
        default:
            return nil;
    }
}



@end
