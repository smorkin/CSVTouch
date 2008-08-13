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
#import "parseCSV.h"

#define FILEPARSER_RAW_DATA @"rawData"
#define FILEPARSER_URL @"URL"


@implementation CSVFileParser

@synthesize filePath = _filePath;
@synthesize URL = _URL;
@synthesize rawString = _rawString;
@synthesize usedDelimiter = _usedDelimiter;
@synthesize hasBeenSorted = _hasBeenSorted;
@synthesize hasBeenParsed = _hasBeenParsed;
@synthesize problematicRow = _problematicRow;
@synthesize droppedRows = _droppedRows;

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
	int maxNumberOfRows = (testing ? 3 : 1000000);
	int csvParseFlags = CSV_TRIM | ([CSVPreferencesController keepQuotes] ? 0 : CSV_QUOTES);
	
	*foundColumns = -1;
	
	[_parsedItems removeAllObjects];
	[_columnNames removeAllObjects];
	[_problematicRow autorelease];
	_problematicRow = nil;
	_droppedRows = 0;
	
	if( [CSVPreferencesController allowRotatableInterface] )
	{
		CSVParser *parser = [[[CSVParser alloc] init] autorelease];
		[parser setEncoding:NSUTF8StringEncoding];
		parser.string = s;
		NSMutableArray *tmp = [parser parseFile];
		
		if( [tmp count] > 0 )
		{
			if( !testing )
			{
				[_columnNames addObjectsFromArray:[tmp objectAtIndex:0]];
				int numberOfColumns = [_columnNames count];
				[tmp removeObjectAtIndex:0];
				numberOfRows = [tmp count];
				NSArray *words;
				for( NSUInteger i = 0 ; i < numberOfRows ; i++ )
				{
					words = [tmp objectAtIndex:i];
					if( [words count] != numberOfColumns )
					{
						_problematicRow = [[NSString stringWithFormat:@"Item %d, content: %@", i+1, words] retain];
						[_columnNames removeAllObjects];
						[_parsedItems removeAllObjects];
						return FALSE;
					}
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
			}
			
		}
		return YES;
	}
	
	while( nextLineStart < length && numberOfRows < maxNumberOfRows )
	{
		[s getLineStart:&lineStart end:&nextLineStart
			contentsEnd:&lineEnd forRange:NSMakeRange(nextLineStart, 0)];
		lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
		line      = [s substringWithRange:lineRange];
		if( csv_row_parse((const unsigned char *)[line cStringUsingEncoding:encoding], 
						  65536, buf, 65536, row, maxWords, delimiter, csvParseFlags) != -1 )
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
				if(!testing &&
				   ![CSVPreferencesController showDebugInfo] && 
					wordNumber < *foundColumns )
				{
					for( int i = 0 ; i < *foundColumns - wordNumber ; i++ )
						[words addObject:@""];
				}
				else
				{
					[_columnNames removeAllObjects];
					[_parsedItems removeAllObjects];
					[words release];
					if( !testing )
					{
						_problematicRow = [[NSString stringWithFormat:@"Row %d: %@", numberOfRows, line] retain];
					}
					return FALSE;
				}
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
		else
		{
			_droppedRows++;
			[_problematicRow release];
			_problematicRow = [[NSString stringWithFormat:@"Row %d: %@", numberOfRows, line] retain];
		}
		numberOfRows++;
	}
	return TRUE;
}

- (void)parseString:(NSString *)s
{    
	int foundColumns;

	if( [CSVPreferencesController smartDelimiter] )
	{
		int bestResult = 0;
		unichar bestDelimiter = ',';
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
		_usedDelimiter = bestDelimiter;
	}
	else
	{
		_usedDelimiter = [[CSVPreferencesController delimiter] characterAtIndex:0]; 
	}
	
	// Parse file
	[self parse:s delimiter:_usedDelimiter testing:NO foundColumns:&foundColumns];
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
	[_problematicRow release];
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
