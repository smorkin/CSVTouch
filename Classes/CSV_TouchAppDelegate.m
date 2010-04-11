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
#import "OzyRotatableTabBarController.h"
#import "CSVDataViewController.h"
#import "CSVPreferencesController.h"
#import "CSVRow.h"
#import "CSVFileParser.h"
#import "TextAlertView.h"
#import "csv.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"
#define FILE_PASSWORD @"filePassword"

@implementation CSV_TouchAppDelegate

@synthesize window;
@synthesize httpStatusCode = _httpStatusCode;
@synthesize fileInspected = _fileInspected;
@synthesize URLsToDownload = _URLsToDownload;
@synthesize readingFileList = _readingFileList;

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
														message:@"" 
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
														message:@"" 
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

+ (NSString *) documentsPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

#define RAW_CSV_FILES_FOLDER @"My Files"

- (void) readRawFileData:(NSData *)data
				fileName:(NSString *)fileName
		 isLocalDownload:(BOOL)isLocalDownload
{
	if( [[self dataController] numberOfFiles] > 0 &&
	   ![[self dataController] fileExistsWithURL:[newFileURL text]] &&
	   [CSVPreferencesController liteVersionRunning] )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Only 1 file allowed"
														message:@"CSV Lite only allows 1 file; please delete the old one before downloading a new. Or buy CSV Touch :-)"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
	else if( self.httpStatusCode >= 400 )
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
		fp.filePath = [[CSV_TouchAppDelegate documentsPath] stringByAppendingPathComponent:fileName];
		fp.filePath = [NSString stringWithFormat:@"%@.csvtouch", fp.filePath];
		if( !isLocalDownload )
		{
			fp.URL = [newFileURL text]; 
		}
		else
		{
			fp.URL = @"";
		}
		fp.downloadDate = [NSDate date];
		[fp saveToFile];
		[[self dataController] newFileDownloaded:fp];
		[fp release];
	}
}

- (void) loadLocalFiles
{
	NSMutableArray *files = [NSMutableArray array];
	NSString *documentsPath = [CSV_TouchAppDelegate documentsPath];
	if( documentsPath )
	{
		NSArray *documents;
		
		// Upgrading to new version using .csvtouch as extension (iPad preparation)
		documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath
																		error:NULL];
		if( ![CSVPreferencesController hasBeenUpgradedToCustomExtension] )
		{
			BOOL failure = FALSE;
			for( NSString *fileName in documents )
			{
				if( ![fileName isEqualToString:RAW_CSV_FILES_FOLDER] &&
				   ![fileName hasPrefix:@"."] &&
				   ![fileName hasSuffix:@".csvtouch"])
				{
					if( [[NSFileManager defaultManager] moveItemAtPath:[documentsPath stringByAppendingPathComponent:fileName]
																toPath:[[documentsPath stringByAppendingPathComponent:fileName] stringByAppendingString:@".csvtouch"]
																 error:NULL] == FALSE )
						failure = TRUE;
				}
			}
			if( failure )
			{
				UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Upgrade failed"
																 message:@"Can't rename files when upgrading!" 
																delegate:self
													   cancelButtonTitle:@"Quit"
													   otherButtonTitles:nil] autorelease];
				alert.tag = UPGRADE_FAILED;
				[alert show];
				return;
			}
			else
			{
				[CSVPreferencesController setHasBeenUpgradedToCustomExtension];
			}

		}
		
		// First import all the potentially manually added files
		NSString *rawDocumentsPath = [documentsPath stringByAppendingPathComponent:RAW_CSV_FILES_FOLDER];
		documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rawDocumentsPath
																		error:NULL];
		for( NSString *fileName in documents )
		{
			if( ![fileName hasPrefix:@"."] )
				[self readRawFileData:[NSData dataWithContentsOfFile:[rawDocumentsPath stringByAppendingPathComponent:fileName]]
							 fileName:fileName
					  isLocalDownload:YES];
			//			[[NSFileManager defaultManager] removeItemAtPath:[rawDocumentsPath stringByAppendingPathComponent:fileName] error:NULL];
		}
		
		// Then read all the files
		documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath
																		error:NULL];
		for( NSString *fileName in documents )
		{
			if( ![fileName isEqualToString:RAW_CSV_FILES_FOLDER] &&
			   ![fileName hasPrefix:@"."])
			{
				CSVFileParser *fp = [CSVFileParser parserWithFile:[documentsPath stringByAppendingPathComponent:fileName]];
				[files addObject:fp];
			}
		}
	}
	[[self dataController] setFiles:files];
}

- (id)init
{
	if (self = [super init])
	{
		sharedInstance = self;
		_URLsToDownload = [[NSMutableArray alloc] init];
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
	
	// Show the Add file window in case no files are present
	if( [[self dataController] numberOfFiles] == 0 )
	{
		[self downloadNewFile:self];
	}
	else if( ![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShown2.0Info"] )
	{
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Version 2.0"
														 message:@"Lots of things have changed in version 2.0. All major settings have been migrated from earlier version, but a few minor ones can't be migrated. Please check CSV Touch settings if something seems strange to you (description for all settings can be found at http://www.ozymandias.se).\nAll feedback is appreciated. Many of the changes are to ensure new features can be added in the future in a good way. Other changes are to make things easier to work with, e.g. searching for items." 
														delegate:self
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
		[alert show];		
	}
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShown2.0Info"];
}

- (void) awakeFromNib
{
	if( [[[UIDevice currentDevice] name] hasSubstring:@"iPad"] )
		[[NSBundle mainBundle] loadNibNamed:@"iPadMainWindow" owner:self options:nil];
	else 
		[[NSBundle mainBundle] loadNibNamed:@"iPhoneMainWindow" owner:self options:nil];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{	
	[[UIApplication sharedApplication] setStatusBarHidden:![CSVPreferencesController showStatusBar] animated:YES];
	startupController.view.frame = [[UIScreen mainScreen] applicationFrame];
	[window addSubview:startupController.view];
	[startupActivityView startAnimating];
	
	// Only show startup activity view if there are files cached
	NSString *documentsPath = [CSV_TouchAppDelegate documentsPath];
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
		[newFileURL resignFirstResponder];
		self.fileInspected = nil;
		[[self dataController] dismissModalViewControllerAnimated:YES];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
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
				[self.URLsToDownload addObject:line];
			else if( !readingSettings && line && [line isEqualToString:@""] )
				readingSettings = TRUE;
			else if( readingSettings && line && ![line isEqualToString:@""] )
				[settings addObject:line];
		}
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
		[s appendFormat:@"Downloaded: %@\n\n", 
		 (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"Available after next download")];
		[s appendFormat:@"File: %@\n\n", fp.filePath];
		fileInfo.text = s;
	}
	else
	{
		fileInfo.text = [error localizedDescription];
	}
	newFileURL.text = fp.URL;
	[[self dataController] presentModalViewController:fileViewController animated:YES];
}


- (void) startDownloadUsingURL:(NSURL *)url
{
	[rawData release];
	rawData = [[NSMutableData alloc] init];
	self.httpStatusCode = 0;
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:300.0];
    connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (!connection)
	{
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

- (void) reloadAllFiles
{
	[self.URLsToDownload removeAllObjects];
	for( CSVFileParser *fp in [[CSVDataViewController sharedInstance] files] )
		[self.URLsToDownload addObject:[fp URL]];
	if( [self.URLsToDownload count] > 0 )
	{
		NSString *URL = [self.URLsToDownload objectAtIndex:0];
		[self downloadFileWithString:URL];
		[self.URLsToDownload removeObjectAtIndex:0];
	}
}

- (void) loadFileList
{
	TextAlertView *alert = [[TextAlertView alloc] initWithTitle:@"File list address:" 
														message:@"" 
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	alert.textField.keyboardType = UIKeyboardTypeURL;
	alert.textField.secureTextEntry = NO;
	alert.tag = CSV_FILE_LIST_SETUP;
	[alert show];
	[alert release];	
}

- (void) readFileListFromURL:(NSString *)URL
{
	if( !URL || [URL isEqualToString:@""] )
		return;
	
	self.readingFileList = TRUE;
	[self slowActivityStarted];
	[self startDownloadUsingURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (void) downloadFileWithString:(NSString *)URL
{
	if( !URL )
		return;
	
	[self slowActivityStarted];
	[self startDownloadUsingURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	// Update this in case you want to download a file from a similar URL later on
	newFileURL.text = URL;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if( textField == newFileURL )
	{
		[self performSelector:@selector(doDownloadNewFile:) withObject:self afterDelay:0];
	}
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
				[self performSelector:@selector(delayedStartup) withObject:nil afterDelay:0.3];
			}
			else
			{
				[self performSelector:@selector(checkPassword) withObject:nil afterDelay:0.3];
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
}

@end
