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
#import "csv.h"

#define SELECTED_TAB_BAR_INDEX @"selectedTabBarIndex"

@implementation CSV_TouchAppDelegate

@synthesize window;

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

+ (CSV_TouchAppDelegate *) sharedInstance
{
	return sharedInstance;
}

- (CSVDataViewController *) dataController
{
	return dataController;
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
		newFileURL.text = @"http//";
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
	[self performSelector:@selector(delayedStartup) withObject:nil afterDelay:0];
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

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	CSVFileParser *fp = [[CSVFileParser alloc] initWithRawData:rawData];
	fp.filePath = [[CSV_TouchAppDelegate documentsPath] stringByAppendingPathComponent:[[newFileURL text] lastPathComponent]];
	fp.URL = [newFileURL text]; 
	fp.downloadDate = [NSDate date];
	[fp saveToFile];
	[[self dataController] newFileDownloaded:fp];
	[fp release];
	[rawData release];
	rawData = nil;
	[self downloadDone];
}

- (IBAction) downloadNewFile:(id)sender
{
	NSMutableString *s = [NSMutableString string];
	[s appendString:@"1. For FTP download, remove \"http://\" and use\n\n"];
	[s appendString:@"ftp://username:password@ftpserver.com/file.csv\n\n"];
	[s appendString:@"2. An example file to test CSV Touch is available at\n\n"];
	[s appendString:@"http://idisk.mac.com/simon_wigzell-Public/Games.csv"];
	fileInfo.text = s;
	[[self dataController] presentModalViewController:downloadNewFileController animated:YES];
}

- (void) showFileInfo:(CSVFileParser *)fp
{
	NSError *error;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fp filePath] error:&error];
	
	if( fileAttributes )
	{
		NSMutableString *s = [NSMutableString string];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[s appendFormat:@"Size: %.2f KB\n", ((double)[[fileAttributes objectForKey:NSFileSize] longLongValue]) / 1024.0];
		[s appendFormat:@"Downloaded: %@\n", 
		 (fp.downloadDate ? [dateFormatter stringFromDate:fp.downloadDate] : @"Not available")];
		fileInfo.text = s;
	}
	else
	{
		fileInfo.text = [error localizedDescription];
	}
	newFileURL.text = [fp URL];
	[[self dataController] presentModalViewController:downloadNewFileController animated:YES];
}
	
	
- (void) startDownloadUsingURL:(NSURL *)url
{
	[rawData release];
	rawData = [[NSMutableData alloc] init];
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
	[self slowActivityStartedInViewController:downloadNewFileController];
	[self startDownloadUsingURL:[NSURL URLWithString:[newFileURL text]]];
}

- (IBAction) cancelDownloadNewFile:(id)sender
{
	[self downloadDone];
}

- (void) downloadFileWithString:(NSString *)URL
{
	[self slowActivityStartedInViewController:[self dataController]];
	[self startDownloadUsingURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

	// Update this if you want to download a file from a similar URL later on
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

- (void) slowActivityStartedInViewController:(UIViewController *)viewController
{
	activityView.frame = viewController.view.frame;
	[viewController.view addSubview:activityView];
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
	

@end
