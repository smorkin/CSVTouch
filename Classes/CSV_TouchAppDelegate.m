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

enum{PASSWORD_CHECK = 1, PASSWORD_SET};

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

- (void) loadLocalFiles
{
	NSMutableArray *files = [NSMutableArray array];
	NSString *documentsPath;
	if( (documentsPath = [CSV_TouchAppDelegate documentsPath]) )
	{
		NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath
																				 error:NULL];
		for( NSString *file in documents )
		{
			CSVFileParser *fp = [CSVFileParser parserWithFile:[documentsPath stringByAppendingPathComponent:file]];
			[files addObject:fp];
		}
	}
	[[self dataController] setFiles:files];
}

- (id)init
{
	if (self = [super init])
	{
		sharedInstance = self;
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
	[super dealloc];
}


- (void) downloadDone
{
	[connection release];
	connection = nil;
	[self slowActivityCompleted];
	[newFileURL resignFirstResponder];
	self.fileInspected = nil;
	[[self dataController] dismissModalViewControllerAnimated:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download Failure"
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
	CSVFileParser *fp = [[CSVFileParser alloc] initWithRawData:rawData];
	fp.filePath = [[CSV_TouchAppDelegate documentsPath] stringByAppendingPathComponent:[[newFileURL text] lastPathComponent]];
	fp.URL = [newFileURL text]; 
	fp.downloadDate = [NSDate date];
	
	if( [[self dataController] numberOfFiles] > 0 &&
	   ![[self dataController] fileExistsWithURL:fp.URL] &&
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
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Download Failure"
														 message:[NSString httpStatusDescription:self.httpStatusCode]
														delegate:self
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];	
		[alert show];
	}
	else
	{
		[fp saveToFile];
		[[self dataController] newFileDownloaded:fp];
	}
	[fp release];
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
	newFileURL.text = [fp URL];
	[[self dataController] presentModalViewController:fileViewController animated:YES];
}
	
	
- (void) startDownloadUsingURL:(NSURL *)url
{
	[rawData release];
	rawData = [[NSMutableData alloc] init];
	self.httpStatusCode = 0;
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:10.0];
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

- (void) downloadFileWithString:(NSString *)URL
{
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
}

@end
