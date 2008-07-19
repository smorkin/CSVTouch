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


@implementation CSV_TouchAppDelegate

@synthesize window;
@synthesize tabBarController;

static CSV_TouchAppDelegate *sharedInstance = nil;

+ (BOOL) allowRotation
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
	return [[tabBarController viewControllers] objectAtIndex:0];
}

- (CSVPreferencesController *) prefsController
{
	return [[tabBarController viewControllers] objectAtIndex:1];
}

//- (IBAction) prefsDone:(id)sender
//{
//	[tabBarController setSelectedViewController:[[tabBarController viewControllers] objectAtIndex:0]];
//}
//
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

- (void) delayedStartup
{
	[self loadLocalFiles];
	[[self prefsController] applicationDidFinishLaunching];
	[[self dataController] applicationDidFinishLaunching];
	
	// Configure and show the window
	[startupController.view removeFromSuperview];
	[window addSubview:tabBarController.view];
	[window makeKeyAndVisible];
	[startupActivityView stopAnimating];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
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
	[[self dataController] applicationWillTerminate];
}

- (void)dealloc {
	[tabBarController release];
	[window release];
	[rawData release];
	[super dealloc];
}

- (void) downloadDone
{
	[downloadActivityView stopAnimating];
	[newFileURL endEditing:YES];
	[tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Failure"
													message:[error localizedDescription]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
	[self downloadDone];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    [rawData appendData:newData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	CSVFileParser *fp = [[CSVFileParser alloc] initWithRawData:rawData];
	fp.filePath = [[CSV_TouchAppDelegate documentsPath] stringByAppendingPathComponent:[[newFileURL text] lastPathComponent]];
	fp.URL = [newFileURL text]; 
	[fp saveToFile];
	[[self dataController] newFileDownloaded:fp];
	[fp release];
	[self downloadDone];
}

- (IBAction) downloadNewFile:(id)sender
{
	[tabBarController presentModalViewController:downloadNewFileController animated:YES];
}

- (IBAction) doDownloadNewFile:(id)sender
{
	[downloadActivityView startAnimating];
	[rawData release];
	rawData = [[NSMutableData alloc] init];
	NSURL *url = [NSURL URLWithString:[newFileURL text]];
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

- (IBAction) cancelDownloadNewFile:(id)sender
{
	[self downloadDone];
}

- (void) openDownloadFileWithString:(NSString *)URL
{
	newFileURL.text = URL;
	[self downloadNewFile:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if( textField == newFileURL )
	{
		[self performSelector:@selector(doDownloadNewFile:) withObject:self afterDelay:0];
	}
	return YES;
}
@end
