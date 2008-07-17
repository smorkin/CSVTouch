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
#import "CSVPreferencesViewController.h"
#import "CSVRow.h"
#import "CSVFileParser.h"
#import "csv.h"

@interface OzyEncodingItem : NSObject
{
	NSString *_userDescription;
	NSStringEncoding _encoding;
	CGFloat _width;
}
@property (nonatomic, copy) NSString *userDescription;
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, assign) CGFloat width;

+ (NSArray *) availableEncodings;
+ (NSString *) userDescriptionForEncoding:(NSStringEncoding) encoding;
+ (NSStringEncoding) encodingForUserDescription:(NSString *) userDescription;
@end

@implementation OzyEncodingItem
@synthesize userDescription = _userDescription;
@synthesize encoding = _encoding;
@synthesize width = _width;

- (id) initWithUserDescription:(NSString *)s encoding:(NSStringEncoding)enc width:(CGFloat)w
{
	self = [super init];
	self.userDescription = s;
	self.encoding = enc;
	self.width = w;
	return self;
}

+ (NSArray *) availableEncodings
{
	static NSMutableArray *items = nil;
	
	if( !items )
	{
		items = [[NSMutableArray alloc] init];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"UTF8" 
																  encoding:NSUTF8StringEncoding
																	 width:0.0] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Unicode" 
																  encoding:NSUnicodeStringEncoding
																	 width:85] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Latin1" 
																  encoding:NSISOLatin1StringEncoding
																	 width:75] autorelease]];
		[items addObject:[[[OzyEncodingItem alloc] initWithUserDescription:@"Mac" 
																  encoding:NSMacOSRomanStringEncoding
																	 width:0.0] autorelease]];
	}
	
	return items;
}

+ (NSString *) userDescriptionForEncoding:(NSStringEncoding) encoding
{
	for( OzyEncodingItem *item in [self availableEncodings] )
		if( item.encoding == encoding)
			return item.userDescription;
	return @"";
}

+ (NSStringEncoding) encodingForUserDescription:(NSString *) userDescription
{
	for( OzyEncodingItem *item in [self availableEncodings] )
		if( [item.userDescription isEqualToString:userDescription] )
			return item.encoding;
	return NSUTF8StringEncoding;
}

@end



@implementation CSV_TouchAppDelegate

@synthesize window;
@synthesize tabBarController;

static CSV_TouchAppDelegate *sharedInstance = nil;

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

- (CSVPreferencesViewController *) prefsController
{
	return [[tabBarController viewControllers] objectAtIndex:1];
}

- (NSInteger) delimiterIndex
{
	return 0;	
}

- (NSString *) delimiter
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *s = [defaults stringForKey:@"delimiter"];
	if( !s )
		s = @";";
	return s;
}

- (void) setDelimiter:(NSString *)s
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:s forKey:@"delimiter"];
}

- (NSInteger) tableViewSize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *s = [defaults stringForKey:@"tableViewSize"];
	if( !s || [s intValue] < 0 || [s intValue] > OZY_MINI )
		return OZY_MINI;
	else
		return [s intValue];
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

- (void) loadPreferences
{
	[sizeControl setTitle:@"Normal" forSegmentAtIndex:0];
	[sizeControl insertSegmentWithTitle:@"Small" atIndex:1 animated:NO];
	[sizeControl insertSegmentWithTitle:@"Mini" atIndex:2 animated:NO];
	sizeControl.selectedSegmentIndex = [self tableViewSize];
	
	[delimiterControl setTitle:@"," forSegmentAtIndex:0];
	[delimiterControl insertSegmentWithTitle:@";" atIndex:1 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"." atIndex:2 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"|" atIndex:3 animated:NO];
	[delimiterControl insertSegmentWithTitle:@"space" atIndex:4 animated:NO];
	[delimiterControl setWidth:80 forSegmentAtIndex:4];  
	[delimiterControl insertSegmentWithTitle:@"tab" atIndex:5 animated:NO];
	[delimiterControl setWidth:60 forSegmentAtIndex:5];
	NSString *delimiter = [self delimiter];
	if( [delimiter isEqualToString:@","] )
		delimiterControl.selectedSegmentIndex = 0;
	else if( [delimiter isEqualToString:@";"] )
		delimiterControl.selectedSegmentIndex = 1;
	else if( [delimiter isEqualToString:@"."] )
		delimiterControl.selectedSegmentIndex = 2;
	else if( [delimiter isEqualToString:@"|"] )
		delimiterControl.selectedSegmentIndex = 3;
	else if( [delimiter isEqualToString:@" "] )
		delimiterControl.selectedSegmentIndex = 4;
	else if( [delimiter isEqualToString:@"\t"] )
		delimiterControl.selectedSegmentIndex = 5;
//	[delimiterControl setEnabled:![self smartDelimiter]];
	delimiterControl.hidden = [self smartDelimiter];

	[smartDelimiterSwitch setOn:[self smartDelimiter] animated:NO];
	
	NSString *userDescription = [OzyEncodingItem userDescriptionForEncoding:[self encoding]];
	NSArray *encodings = [OzyEncodingItem availableEncodings];
	OzyEncodingItem *item;
	for( NSUInteger i = 0 ; i < [encodings count] ; i++ )
	{
		item = [encodings objectAtIndex:i];
		if( i == 0 )
			[encodingControl setTitle:item.userDescription forSegmentAtIndex:0];
		else
			[encodingControl insertSegmentWithTitle:item.userDescription atIndex:i animated:NO];
		[encodingControl setWidth:item.width forSegmentAtIndex:i];
		if( [userDescription isEqualToString:item.userDescription] )
			encodingControl.selectedSegmentIndex = i;
	}
	
	NSString *sorting = [[NSUserDefaults standardUserDefaults] objectForKey:@"sortingMask"];
	if( sorting )
		sortingMask = [sorting intValue];
	else
		sortingMask = 0;
	[numericCompareSwitch setOn:((sortingMask & NSNumericSearch) != 0) animated:NO];
	[caseInsensitiveCompareSwitch setOn:((sortingMask & NSCaseInsensitiveSearch) != 0) animated:NO];
	
	maxNumberOfObjectsToSort.text = [NSString stringWithFormat:@"%d", [self maxNumberOfObjectsToSort]];
}

- (NSUInteger) maxNumberOfObjectsToSort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"maxNumberOfObjectsToSort"];
}	

- (void) delayedStartup
{
	[self loadLocalFiles];
	[self loadPreferences];
	[[self dataController] applicationDidFinishLaunching];
	[[self prefsController] applicationDidFinishLaunching];
	
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
	[fp release];
	[self loadLocalFiles];
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

- (IBAction) refreshFile:(id)sender
{
	CSVFileParser *fp = [[self dataController] currentFile];
	if( fp )
	{
		newFileURL.text = fp.URL;
		[self downloadNewFile:self];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No File Selected"
														message:@"Please select a file to refresh"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if( textField == newFileURL )
	{
		[self performSelector:@selector(doDownloadNewFile:) withObject:self afterDelay:0];
	}
	else if( textField == maxNumberOfObjectsToSort )
	{
		[maxNumberOfObjectsToSort endEditing:YES];
		int newValue = [maxNumberOfObjectsToSort.text intValue];
		NSUInteger oldValue = [self maxNumberOfObjectsToSort];
		if( oldValue != newValue && newValue >= 0 )
		{
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setInteger:newValue forKey:@"maxNumberOfObjectsToSort"];
			if( newValue == 0 || newValue > oldValue )
				[[self dataController] resortObjects];
		}
	}
	return YES;
}

- (IBAction) sizeControlChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInt:[sizeControl selectedSegmentIndex]]
				 forKey:@"tableViewSize"];
	[[self dataController] setSize:[sizeControl selectedSegmentIndex]];
}
	
- (IBAction) delimiterControlChanged:(id)sender
{
	switch( [delimiterControl selectedSegmentIndex] )
	{
		case 0:
			[self setDelimiter:@","];
			break;
		case 1:
			[self setDelimiter:@";"];
			break;
		case 2:
			[self setDelimiter:@"."];
			break;
		case 3:
			[self setDelimiter:@"|"];
			break;
		case 4:
			[self setDelimiter:@" "];
			break;
		case 5:
			[self setDelimiter:@"\t"];
			break;
		default:
			break;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[smartDelimiterSwitch isOn] forKey:@"smartDelimiter"];
//	[delimiterControl setEnabled:![self smartDelimiter]];
	delimiterControl.hidden = [self smartDelimiter];
	[[self dataController] reparseFiles];
}

- (BOOL) smartDelimiter
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"smartDelimiter"];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] boolForKey:@"smartDelimiter"];
	else
		return YES;
}

- (IBAction) encodingControlChanged:(id)sender
{
	NSStringEncoding encoding = [OzyEncodingItem encodingForUserDescription:
								 [encodingControl titleForSegmentAtIndex:[encodingControl selectedSegmentIndex]]];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSString stringWithFormat:@"%d", encoding] forKey:@"encoding"];
}

- (NSStringEncoding) encoding
{
	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"encoding"];
	if( obj )
		return [[NSUserDefaults standardUserDefaults] integerForKey:@"encoding"];
	else
		return NSUTF8StringEncoding;
}

NSUInteger sortingMask;

- (IBAction) sortingChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	sortingMask = 0;
	if( [numericCompareSwitch isOn] )
		sortingMask ^= NSNumericSearch;
	if( [caseInsensitiveCompareSwitch isOn] )
		sortingMask ^= NSCaseInsensitiveSearch;
	[defaults setObject:[NSString stringWithFormat:@"%d", sortingMask] forKey:@"sortingMask"];
	[[self dataController] resortObjects];
}	

@end
