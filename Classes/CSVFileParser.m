//
//  CSVFileParser.m
//  CSV Touch
//
//  Created by Simon Wigzell on 03/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVFileParser.h"
#import "CSVRow.h"
#import "CSVPreferencesController.h"
#import "CSV_TouchAppDelegate.h"
#import "OzyTableViewController.h"
#import "csv.h"

#define FILEPARSER_RAW_DATA @"rawData"
#define FILEPARSER_URL @"URL"

@implementation CSVFileParser

@synthesize filePath = _filePath;
@synthesize URL = _URL;
@synthesize hasBeenSorted = _hasBeenSorted;
@synthesize hasBeenParsed = _hasBeenParsed;

- (NSArray *) availableColumnNames
{
	return _columnNames;
}

- (void) invalidateShortDescriptions
{
	for( CSVRow *row in _parsedItems )
		row.shortDescription = nil;
}
- (NSMutableArray *) itemsWithResetShortdescriptions:(BOOL)reset
{
	if( reset )
		[self invalidateShortDescriptions];
	return _parsedItems;
}

// Returns FALSE if error is encountered
- (BOOL) parse:(NSString *)s
	 delimiter:(int)delimiter
	   testing:(BOOL)testing
  foundColumns:(int *)foundColumns
{
	int numberOfRows = 0;
	NSUInteger lineStart, lineEnd, nextLineStart;
	NSUInteger length = [s length];
	NSRange lineRange;
	NSString *line;
	int maxWords = 64;
	unsigned char buf[1000000];
	unsigned char *row[maxWords];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:(testing ? 2 : 5000)];
	lineStart = lineEnd = nextLineStart = 0;
	NSUInteger encoding = [CSVPreferencesController encoding];
	int maxNumberOfRows = (testing ? 5 : 1000000);
	*foundColumns = -1;
	
	[_parsedItems removeAllObjects];
	[_columnNames removeAllObjects];
	while( nextLineStart < length && numberOfRows < maxNumberOfRows )
	{
		[s getLineStart:&lineStart end:&nextLineStart
			contentsEnd:&lineEnd forRange:NSMakeRange(nextLineStart, 0)];
		lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
		line      = [s substringWithRange:lineRange];
		if( csv_row_parse((const unsigned char *)[line cStringUsingEncoding:encoding], 
						  65536, buf, 65536, row, maxWords, delimiter, CSV_TRIM | CSV_QUOTES) != -1 )
		{
			int wordNumber = 0;
			NSString *word;
			NSMutableArray *words = [[NSMutableArray alloc] init];
			while( row[wordNumber] != '\0' && wordNumber < maxWords)
			{
				if( [result count] < wordNumber+1 )
					[result addObject:[NSMutableArray array]];
				word = [[NSString alloc] initWithBytes:row[wordNumber] 
												length:strlen((const char *)row[wordNumber]) 
											  encoding:encoding];
				[words addObject:word];
				[word release];
				wordNumber++;
			}
			
			// Check for consistency
			if( *foundColumns == -1 )
				*foundColumns = wordNumber;
			else if( *foundColumns != wordNumber && wordNumber != 0 )
			{
				[_columnNames removeAllObjects];
				[_parsedItems removeAllObjects];
				[words release];
				return FALSE;
			}
			
			// Add data if not testing
			if( !testing )
			{
				if( numberOfRows == 0 )
					[_columnNames addObjectsFromArray:words];
				else
				{
					CSVRow *row = [[CSVRow alloc] init];
					row.items = words;
					row.fileParser = self;
					row.rawDataPosition = numberOfRows;
					[_parsedItems addObject:row];
					[row release];
				}
			}
			
			[words release];
		}
		numberOfRows++;
	}
	return TRUE;
}

- (void)parseString:(NSString *)s
{    
	int delimiter;
	int foundColumns;

	if( [CSVPreferencesController smartDelimiter] )
	{
		int bestResult = 0;
		int bestDelimiter = 0;
		for( NSString *testDelimiter in [CSV_TouchAppDelegate allowedDelimiters] )
		{
			if([self parse:s delimiter:[testDelimiter characterAtIndex:0] testing:YES foundColumns:&foundColumns] &&
			   foundColumns > 0 &&
			   foundColumns > bestResult )
			{
				bestResult = foundColumns;
				bestDelimiter = [testDelimiter characterAtIndex:0];
			}
		}
		delimiter = bestDelimiter;
	}
	else
	{
		delimiter = [[CSVPreferencesController delimiter] characterAtIndex:0]; 
	}
	
	// Check for errors
	if( ![self parse:s delimiter:delimiter testing:NO foundColumns:&foundColumns] )
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File Parsing Error"
														message:@"Different number of objects in different columns"
													   delegate:[CSV_TouchAppDelegate sharedInstance]
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];				
		return;
	}
}

- (void) parseIfNecessary
{
	if( !_hasBeenParsed )
	{
		[self parseString:_rawString];	
		_hasBeenParsed = YES;
	}
}

- (void) reparseIfParsed
{
	if( _hasBeenParsed )
	{
		[self parseString:_rawString];	
	}
}

- (id) initWithRawData:(NSData *)d
{
	[super init];
	_parsedItems = [[NSMutableArray alloc] init];
	_columnNames = [[NSMutableArray alloc] init];
	_rawData = [d retain];
	_rawString = [[NSString alloc] initWithData:_rawData 
									   encoding:[CSVPreferencesController encoding]];
	_hasBeenParsed = NO;
	return self;
}

- (void) dealloc
{
	[_parsedItems release];
	[_columnNames release];
	[_rawString release];
	[_rawData release];
	self.URL = nil;
	self.filePath = nil;
	[super dealloc];
}

- (NSString *) fileName
{
	return [self.filePath lastPathComponent];
}

- (NSUInteger) stringLength
{
	return [_rawString length];
}

+ (CSVFileParser *) parserWithFile:(NSString *)path
{
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	CSVFileParser *fp = [[[self alloc] initWithRawData:[d objectForKey:FILEPARSER_RAW_DATA]] autorelease];
	fp.filePath = path;
	fp.URL = [d objectForKey:FILEPARSER_URL];
	return fp;
}

- (void) saveToFile
{
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:_rawData, FILEPARSER_RAW_DATA,
					   self.URL, FILEPARSER_URL,
					   nil];
	[d writeToFile:self.filePath atomically:YES];
}

@end

@implementation CSVFileParser (OzyTableViewProtocol)

- (NSString *) tableViewDescription
{
	NSString *s = [[self filePath] lastPathComponent];
	if( [[[s pathExtension] lowercaseString] isEqualToString:@"csv"] )
		return [s stringByDeletingPathExtension];
	else
		return s;
}

- (NSComparisonResult) compareFileName:(CSVFileParser *)fp
{
	return [[self tableViewDescription] compare:[fp tableViewDescription] options:NSNumericSearch];
}

@end
