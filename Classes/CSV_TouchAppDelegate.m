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
#import "TextAlertView.h"
#import "csv.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"
#define FILE_PASSWORD @"filePassword"
#define MANUALLY_ADDED_URL_VALUE @""
#define INTERNAL_EXTENSION @".csvtouch"

@implementation CSV_TouchAppDelegate

@synthesize window;
@synthesize httpStatusCode = _httpStatusCode;
@synthesize fileInspected = _fileInspected;
@synthesize URLsToDownload = _URLsToDownload;
@synthesize filesAddedThroughURLList = _filesAddedThroughURLList;
@synthesize readingFileList = _readingFileList;
@synthesize downloadFailed = _downloadFailed;
@synthesize enteredBackground = _enteredBackground;

static CSV_TouchAppDelegate *sharedInstance = nil;

- (BOOL) allowRotation
{
	return [CSVPreferencesController allowRotatableInterface];	
}

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
	TextAlertView *alert = [[TextAlertView alloc] initWithTitle:@"Input Password" 
													   delegate:self
											  cancelButtonTitle:@"Quit"
											  otherButtonTitles:@"OK", nil];
	alert.textField.keyboardType = UIKeyboardTypeDefault;
	alert.textField.secureTextEntry = YES;
	alert.tag = PASSWORD_CHECK;
	[alert show];
	[alert release];
}

- (void) setPassword:(NSString *)title
{
	TextAlertView *alert = [[TextAlertView alloc] initWithTitle:title 
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"OK", nil];
	alert.textField.keyboardType = UIKeyboardTypeDefault;
	alert.textField.secureTextEntry = YES;
	alert.tag = PASSWORD_SET;
	[alert show];
	[alert release];
}

//- (IBAction) newPasswordDone
//{
//	static BOOL emptyPasswordWarned = FALSE;
//	
//	if( ![newPassword1.text isEqualToString:newPassword2.text] )
//	{
//		newPassword1.text = @"";	
//		newPassword2.text = @"";	
//		[newPassword1 becomeFirstResponder];
//		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Password mismatch!"
//														 message:@"Please re-enter the password" 
//														delegate:self
//											   cancelButtonTitle:@"OK"
//											   otherButtonTitles:nil] autorelease];
//		[alert show];
//	}
//	else if( [newPassword1.text length] == 0 && !emptyPasswordWarned )
//	{
//		[newPassword1 becomeFirstResponder];
//		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Empty Password!"
//														 message:@"This is probably not a good idea, but if you are certain, go ahead!" 
//														delegate:self
//											   cancelButtonTitle:@"OK"
//											   otherButtonTitles:nil] autorelease];
//		[alert show];
//		emptyPasswordWarned = TRUE;
//	}
//	else
//	{
//		[[NSUserDefaults standardUserDefaults] setObject:[newPassword1.text ozyHash]
//												  forKey:FILE_PASSWORD];
//		[newPasswordModalController dismissModalViewControllerAnimated:YES];
//	}
//}

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
	
	if( [CSVPreferencesController useBlackTheme] )
	{
		[self dataController].navigationBar.barStyle = UIBarStyleBlackOpaque;
		[self dataController].itemsToolbar.barStyle = UIBarStyleBlackOpaque;
		[self dataController].filesToolbar.barStyle = UIBarStyleBlackOpaque;
		[self dataController].searchBar.barStyle = UIBarStyleBlackOpaque;
		downloadToolbar.barStyle = UIBarStyleBlackOpaque;
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	}		
	
	// Configure and show the window
	[startupActivityView stopAnimating];
	[startupController.view removeFromSuperview];
	
	[window addSubview:[[self dataController] view]];
	[window makeKeyAndVisible];
	
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
	
	// Show the Add file window in case no files are present
	if( [[self dataController] numberOfFiles] == 0 )
	{
		[self downloadNewFile:self];
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
	[[UIApplication sharedApplication] setStatusBarHidden:![CSVPreferencesController showStatusBar] withAnimation:YES];
	startupController.view.frame = [[UIScreen mainScreen] applicationFrame];
	[window addSubview:startupController.view];
	[startupActivityView startAnimating];
	
	// Only show startup activity view if there are files cached
	NSString *documentsPath = [CSV_TouchAppDelegate importedDocumentsPath];
	if( documentsPath && [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath
																			  error:NULL] count] > 0 )
	{
		[window makeKeyAndVisible];
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
	[window release];
	[rawData release];
	[self.URLsToDownload release];
	[self.filesAddedThroughURLList release];
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
	[s appendString:@"2. An example file to test CSV Touch is available at\n\n"];
	[s appendString:@"http://idisk.mac.com/simon_wigzell-Public/Games.csv\n\n"];
	[s appendString:@"Note the capital \"P\" and \"G\", and the \"-\"."];
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
	TextAlertView *alert = [[TextAlertView alloc] initWithTitle:@"File list address:" 
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	alert.textField.keyboardType = UIKeyboardTypeURL;
	alert.textField.secureTextEntry = NO;
    if( [CSVPreferencesController lastUsedListURL] )
        alert.textField.text = [[CSVPreferencesController lastUsedListURL] absoluteString];
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
	[window addSubview:activityView];
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
	int maxMinutesInBackground = [CSVPreferencesController maxSafeBackgroundMinutes];
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
	TextAlertView *alertView = (TextAlertView*) actionSheet;
	if(alertView.tag == PASSWORD_CHECK)
	{
		if(buttonIndex > 0)
		{
			if( [[alertView.textField.text ozyHash] isEqual:[[NSUserDefaults standardUserDefaults] dataForKey:FILE_PASSWORD]] )
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
	else if(alertView.tag == PASSWORD_SET)
	{
		if(buttonIndex > 0)
		{
			if( newPassword == nil )
			{
				newPassword = [alertView.textField.text copy];
				[self performSelector:@selector(setPassword:)
						   withObject:@"Confirm Password"
						   afterDelay:0.3];
			}
			else if( [alertView.textField.text isEqual:newPassword] )
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
	else if( alertView.tag == CSV_FILE_LIST_SETUP )
	{
		[self readFileListFromURL:alertView.textField.text];
	}
	else if( alertView.tag == UPGRADE_FAILED )
	{
		exit(1);
	}
	else if( alertView.tag == RELOAD_FILES && buttonIndex > 0)
	{
		[self reloadAllFiles];
	}
}

@end
