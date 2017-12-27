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
#import "CSVDataViewController.h"
#import "OzyTableViewController.h"
#import "csv.h"
#import "parseCSV.h"

#define FILEPARSER_RAW_DATA @"rawData"
#define FILEPARSER_URL @"URL"
#define FILEPARSER_DOWNLOAD_DATE @"downloadDate"
#define FILEPARSER_HIDE_ADDRESS @"hideAdress"

#define ITEM_ICON_COLUMN_NAME @"CSV Touch icon"

#define DEFS_ENCODING_FOR_FILES @"encodingForFiles"

@interface CSVFileParser ()
@property (nonatomic, strong) NSMutableArray *parsedItems;
@property (nonatomic, copy) NSData *rawData;
@property (nonatomic, strong) NSMutableArray *shownColumnNames;
@end

@implementation CSVFileParser

static NSMutableDictionary *encodingForFileName;
static NSArray *_allowedEncodings = nil;
static NSArray *_allowedEncodingNames = nil;
static NSMutableArray *_files;

+ (NSMutableArray *) files
{
    return _files;
}

+ (NSArray *) allowedFileEncodings
{
    return _allowedEncodings;
}
+ (NSArray *) allowedFileEncodingNames
{
    return _allowedEncodingNames;
}

+ (void) addParser:(CSVFileParser *)parser
{
    [_files addObject:parser];
    [_files sortUsingSelector:@selector(compareFileName:)];
}

+ (void) removeFile:(CSVFileParser *)parser
{
    [_files removeObject:parser];
}

+ (void) removeFileWithName:(NSString *)name
{
    for( CSVFileParser *oldFile in _files )
    {
        if( [name isEqualToString:[oldFile fileName]] )
        {
            [_files removeObject:oldFile];
            return;
        }
    }
}

+ (BOOL) fileExistsWithURL:(NSString *)URL
{
    for( CSVFileParser *fp in _files )
    {
        if( [fp.URL isEqualToString:URL] )
            return YES;
    }
    return NO;
}

#define DEFS_COLUMN_NAMES @"defaultColumnNames"

+ (void) saveColumnNames
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for( CSVFileParser *parser in self.files)
    {
        [d setObject:parser.shownColumnNames forKey:parser.fileName];
    }
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:DEFS_COLUMN_NAMES];
}

+ (NSMutableArray *) shownColumnsFromDefaults:(CSVFileParser *)parser
{
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] objectForKey:DEFS_COLUMN_NAMES];
    if( d && [d isKindOfClass:[NSDictionary class]])
    {
        NSArray *cols = [d objectForKey:parser.fileName];
        if( cols && [cols isKindOfClass:[NSArray class]])
        {
            return [NSMutableArray arrayWithArray:cols];
        }
    }
    return nil;
}

 - (void) loadFile
{
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:self.filePath];
	self.URL = [d objectForKey:FILEPARSER_URL];
	self.downloadDate = [d objectForKey:FILEPARSER_DOWNLOAD_DATE];
	if( [d objectForKey:FILEPARSER_HIDE_ADDRESS] )
		self.hideAddress = [[d objectForKey:FILEPARSER_HIDE_ADDRESS] boolValue];
	else
		self.hideAddress = NO;
    _rawData = [d objectForKey:FILEPARSER_RAW_DATA];
	if( _rawData )
	{
        _rawString = [[NSString alloc] initWithData:_rawData
										   encoding:[CSVFileParser getEncodingForFile:[self fileName]]];
    }
}

- (NSString *) URL
{
	if( !_URL )
		[self loadFile];
	return _URL;
}

- (NSDate *) downloadDate
{
	if( !_URL )
		[self loadFile];
    return _downloadDate;
}

- (void) invalidateShortDescriptions
{
	for( CSVRow *row in self.parsedItems )
		row.shortDescription = nil;
}
- (NSMutableArray *) itemsWithResetShortdescriptions:(BOOL)reset
{
	if( reset )
		[self invalidateShortDescriptions];
	return self.parsedItems;
}

// Returns FALSE if error is encountered
- (BOOL) parse:(NSString *)s
	 delimiter:(int)delimiter
	   testing:(BOOL)testing
  foundColumns:(int *)foundColumns
	useCorrect:(BOOL)useCorrect
{
    NSUInteger encoding = NSUTF8StringEncoding; // Use an encoding which works fine w c-string
	int csvParseFlags = CSV_TRIM | ([CSVPreferencesController keepQuotes] ? 0 : CSV_QUOTES);
	int *columnWidths = NULL;
	
	*foundColumns = -1;
	[self.parsedItems removeAllObjects];
	[self.columnNames removeAllObjects];
	self.problematicRow = nil;
	_droppedRows = 0;
	self.iconIndex = NSNotFound;
	
	if( useCorrect )
	{
		NSUInteger numberOfRows = 0;
		CSVParser *parser = [[CSVParser alloc] init];
		[parser setEncoding:encoding];
		[parser setDelimiter:delimiter];
		parser.string = s;
		NSMutableArray *tmp = [parser parseFile];
		
		if( [tmp count] > 0 )
		{
			if( !testing )
			{
				[self.columnNames addObjectsFromArray:[tmp objectAtIndex:0]];
				NSUInteger numberOfColumns = [self.columnNames count];
				if( (self.iconIndex = [self.columnNames indexOfObject:ITEM_ICON_COLUMN_NAME]) != NSNotFound )
					[self.columnNames removeObjectAtIndex:self.iconIndex];
				[tmp removeObjectAtIndex:0];
				if( [CSVPreferencesController definedFixedWidths] )
				{
					if( [tmp count] == 0 )
					{
						self.problematicRow = @"No row with defined widths found";
						return FALSE;
					}
					NSArray *widths = [tmp objectAtIndex:0];
					int columnNumber = 0;
					columnWidths = malloc([widths count] * sizeof(int));
					for( NSString *width in widths )
						columnWidths[columnNumber++] = [width intValue];
					[tmp removeObjectAtIndex:0];
				}
				numberOfRows = [tmp count];
				NSMutableArray *words;
				for( NSUInteger rawrow = 0 ; rawrow < numberOfRows ; rawrow++ )
				{
					words = [tmp objectAtIndex:rawrow];
					if( [words count] != numberOfColumns )
					{
						self.problematicRow = [NSString stringWithFormat:@"Found %lu values, expected %lu.\nItem %lu, content: %@",
											   (unsigned long)[words count],
											   (unsigned long)numberOfColumns,
											   (unsigned long)rawrow+1,
											   words];
						[self.columnNames removeAllObjects];
						[self.parsedItems removeAllObjects];
						return FALSE;
					}
					else
					{
						CSVRow *csvrow = [[CSVRow alloc] initWithItemCapacity:[self.columnNames count]];
						if( self.iconIndex != NSNotFound )
						{
							csvrow.imageName = [words objectAtIndex:self.iconIndex];
							[words removeObjectAtIndex:self.iconIndex];
						}
						csvrow.items = words;
						if( columnWidths != NULL )
						{
							[csvrow.fixedWidthItems removeAllObjects];
							for( int col = 0 ; col < [self.columnNames count] ; col++ )
							{
								if( columnWidths[col] > 0 )
									[csvrow.fixedWidthItems addObject:[[words objectAtIndex:col] stringByPaddingToLength:columnWidths[col]
																										 withString:@" "
																									startingAtIndex:0]];
								else 
									[csvrow.fixedWidthItems addObject:[words objectAtIndex:col]];
							}
						}
						csvrow.fileParser = self;
						csvrow.rawDataPosition = numberOfRows;
						[self.parsedItems addObject:csvrow];
					}
				}
			}
			
		}
	}
	else
	{
		NSRange lineRange;
		int numberOfRows = 0;
		NSUInteger lineStart, lineEnd, nextLineStart;
		NSString *line;
		int maxWords = 64;
		unsigned char buf[1000000];
		unsigned char *row[maxWords];
		NSMutableArray *result = [NSMutableArray arrayWithCapacity:(testing ? 2 : 5000)];
		int maxNumberOfRows = (testing ? 3 : 1000000);
		NSUInteger length = [s length];

		lineStart = lineEnd = nextLineStart = 0;
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
						[self.columnNames removeAllObjects];
						[self.parsedItems removeAllObjects];
						if( !testing )
						{
							self.problematicRow = [NSString stringWithFormat:@"Found %d values, expected %d.\nItem %d:\n%@",
												   wordNumber,
												   *foundColumns,
												   numberOfRows, 
												   line];
						}
						return FALSE;
					}
				}
				
				// Add data if not testing
				if( !testing )
				{
					if( numberOfRows == 0 )
					{
						[self.columnNames addObjectsFromArray:words];
						if( (self.iconIndex = [self.columnNames indexOfObject:ITEM_ICON_COLUMN_NAME]) != NSNotFound )
						{
							[self.columnNames removeObjectAtIndex:self.iconIndex];
						}
					}
					else if(numberOfRows == 1 &&
							[CSVPreferencesController definedFixedWidths])
					{
						if( self.iconIndex != NSNotFound )
							[words removeObjectAtIndex:self.iconIndex];
						NSArray *widths = words;
						int columnNumber = 0;
						columnWidths = malloc([widths count] * sizeof(int));
						for( NSString *width in widths )
							columnWidths[columnNumber++] = [width intValue];
					}
					else
					{
						CSVRow *csvrow = [[CSVRow alloc] initWithItemCapacity:[self.columnNames count]];
						if( self.iconIndex != NSNotFound )
						{
							csvrow.imageName = [words objectAtIndex:self.iconIndex];
							[words removeObjectAtIndex:self.iconIndex];
						}
						csvrow.items = words;
						if( columnWidths != NULL )
						{
							[csvrow.fixedWidthItems removeAllObjects];
							for( int i = 0 ; i < [self.columnNames count] ; i++ )
							{
								if( columnWidths[i] > 0 )
									[csvrow.fixedWidthItems addObject:[[words objectAtIndex:i] stringByPaddingToLength:columnWidths[i]
																										 withString:@" "
																									startingAtIndex:0]];
								else 
									[csvrow.fixedWidthItems addObject:[words objectAtIndex:i]];
								}
						}
						csvrow.fileParser = self;
						csvrow.rawDataPosition = numberOfRows;
						[self.parsedItems addObject:csvrow];
					}
				}				
			}
			else
			{
				_droppedRows++;
				self.problematicRow = [NSString stringWithFormat:@"Row %d: %@", numberOfRows, line];
			}
			numberOfRows++;
		}
	}
	
	if( columnWidths != NULL )
		free( columnWidths);
									  
	return TRUE;
}

- (unichar) delimiter
{
	if( [CSVPreferencesController smartDelimiter] )
	{
		int foundColumns;
		int bestResult = 0;
		unichar bestDelimiter = ',';
		for( NSString *testDelimiter in [CSV_TouchAppDelegate allowedDelimiters] )
		{
			if([self parse:_rawString 
				 delimiter:[testDelimiter characterAtIndex:0]
				   testing:YES
			  foundColumns:&foundColumns
				useCorrect:NO] &&
			   foundColumns > 0 &&
			   foundColumns > bestResult )
			{
				bestResult = foundColumns;
				bestDelimiter = [testDelimiter characterAtIndex:0];
			}
		}
		return bestDelimiter;
	}
	else
	{
		return [[CSVPreferencesController delimiter] characterAtIndex:0]; 
	}
	
}

- (void)parseString
{    
	if( !_rawData )
		[self loadFile];
	
	int foundColumns;
	_usedDelimiter = [self delimiter];
	
	// Parse file
	[self parse:_rawString
	  delimiter:_usedDelimiter
		testing:NO
   foundColumns:&foundColumns
	 useCorrect:[CSVPreferencesController useCorrectParsing]];
}

- (void) parseIfNecessary
{
	if( !_hasBeenParsed )
	{		
		[self parseString];	
		_hasBeenParsed = YES;
	}
}

- (void) reparseIfParsed
{
	if( _hasBeenParsed )
	{
		[self parseString];	
	}
}

- (void) encodingUpdated
{
    _rawString = nil;
    if( _rawData)
    {
        _rawString = [[NSString alloc] initWithData:_rawData
										   encoding:[CSVFileParser getEncodingForFile:[self fileName]]];
    }
    [self reparseIfParsed];
    [self resetColumnsInfo];
}

- (id) initWithRawData:(NSData *)d filePath:(NSString *)path
{
	self = [super init];
	self.parsedItems = [[NSMutableArray alloc] init];
	self.columnNames = [[NSMutableArray alloc] init];
	_rawData = d;
    self.filePath = path;
	if( _rawData )
	{
        _rawString = [[NSString alloc] initWithData:_rawData
										   encoding:[CSVFileParser getEncodingForFile:[self fileName]]];
    }
	self.hasBeenParsed = NO;
    [CSVFileParser addParser:self];
	return self;
}

- (void) dealloc
{
    self.parsedItems = nil;
    self.columnNames = nil;
    _rawString = nil;
    _rawData = nil;
	self.problematicRow = nil;
	self.URL = nil;
	self.downloadDate = nil;
	self.filePath = nil;
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
	CSVFileParser *fp = [[self alloc] initWithRawData:nil filePath:path];
	return fp;
}

- (void) saveToFile
{
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:_rawData, FILEPARSER_RAW_DATA,
					   self.URL, FILEPARSER_URL,
					   self.downloadDate, FILEPARSER_DOWNLOAD_DATE,
					   [NSNumber numberWithBool:self.hideAddress], FILEPARSER_HIDE_ADDRESS,
					   nil];
	[d writeToFile:self.filePath atomically:YES];
}

- (NSString *) parseErrorString
{
    NSMutableString *s = [NSMutableString string];
    
    // What type of problem?
    if( self.problematicRow && ![self.problematicRow isEqualToString:@""] )
    {
        [s appendFormat:@"Wrong number of objects in row(s). Potentially first problematic row:\n\n%@\n\n", self.problematicRow];
        if( [CSVPreferencesController keepQuotes] && [self.problematicRow hasSubstring:@"\""])
            [s appendString:@"Try switching off the \"Keep Quotes\"-setting."];
    }
    else if( [self.rawString length] == 0 )
    {
        [s appendString:@"Couldn't read the file using the selected encoding."];
    }
    else
    {
        [s appendFormat:@"Found %lu items in %lu columns, using delimiter '%C'; check \"Data\" preferences.\n\n",
         (unsigned long)[[self itemsWithResetShortdescriptions:NO] count],
         (unsigned long)[self.columnNames count],
         self.usedDelimiter];
        [s appendFormat:@"File read when using the selected encoding:\n\n%@", self.rawString];
    }
    
    return s;
}

- (void) updateRawColumnIndexes
{
    if( self.rawShownColumnIndexes)
    {
        free(self.rawShownColumnIndexes);
        self.rawShownColumnIndexes = NULL;
    }
    self.shownColumnIndexes = [NSMutableArray array];
    for( NSString *usedColumn in self.shownColumnNames )
    {
        for( NSUInteger i = 0 ; i < [self.columnNames count] ; i++ )
            if( [usedColumn isEqualToString:[self.columnNames objectAtIndex:i]] )
                [self.shownColumnIndexes addObject:[NSNumber numberWithUnsignedInteger:i]];
    }
    self.rawShownColumnIndexes = malloc(sizeof(int) * [self.shownColumnIndexes count]);
    for( int i = 0 ; i < [self.shownColumnIndexes count] ; i++ )
    {
        self.rawShownColumnIndexes[i] = [[self.shownColumnIndexes objectAtIndex:i] intValue];
    }
}

- (void) updateColumnsInfoWithShownColumns:(NSArray *)shown
{
    // If we have something in shown, use that for shown columns
    // If not, if we have hidden stuff, use that
    // If not, take shown from defaults
    // If no defaults, shown = all
    if( [shown count] > 0 )
    {
        self.shownColumnNames = [NSMutableArray arrayWithArray:shown];
    }
    else if( [self.hiddenColumns count] > 0){
        [self.shownColumnNames removeAllObjects];
        for( NSUInteger index = 0 ; index < [self.columnNames count] ; index++)
        {
            if( ![self.hiddenColumns containsIndex:index] )
                [self.shownColumnNames addObject:[self.columnNames objectAtIndex:index]];
        }
    }
    else
    {
        self.shownColumnNames = [CSVFileParser shownColumnsFromDefaults:self];
        if( [self.shownColumnNames count] == 0 ){
            self.shownColumnNames = [self.columnNames copy];
        }
    }
    
    [self updateRawColumnIndexes];
}

- (void) updateColumnsInfo
{
    [self updateColumnsInfoWithShownColumns:nil];
}

- (void) resetColumnsInfo
{
    self.shownColumnNames = [self.columnNames copy];
    [self updateRawColumnIndexes];
    self.hasBeenSorted = FALSE;
}

@end

@implementation CSVFileParser (OzyTableViewProtocol)

- (NSString *) defaultTableViewDescription
{
	NSString *s = [[self filePath] lastPathComponent];
	
	// First remove the .csvtouch extension. Should always be there, but we need to be careful about
	// backwards compatibility
	if( [[[s pathExtension] lowercaseString] isEqualToString:@"csvtouch"] )
		s = [s stringByDeletingPathExtension];
	
	// Then we remove standard csv file extensions
	if( [[[s pathExtension] lowercaseString] isEqualToString:@"csv"] ||
	   [[[s pathExtension] lowercaseString] isEqualToString:@"tsv"] ||
	   [[[s pathExtension] lowercaseString] isEqualToString:@"txt"] )
		return [s stringByDeletingPathExtension];
	else
		return s;
}

- (NSString *) tableViewDescription
{
	if( self.hasBeenDownloaded )
		return [NSString stringWithFormat:@"✓ %@", [self defaultTableViewDescription]];	
	else
		return [self defaultTableViewDescription];
}

- (NSComparisonResult) compareFileName:(CSVFileParser *)fp
{
	return [[self defaultTableViewDescription] compare:[fp defaultTableViewDescription] options:NSNumericSearch];
}

- (NSString *) imageName
{
	NSDate *nextDownload = [CSVPreferencesController nextDownload];
	if(self.downloadDate && nextDownload &&
	   [nextDownload timeIntervalSinceDate:self.downloadDate] > 24*60*60 )
		return @"alert.png";
		
	return nil;
}

- (NSString *) emptyImageName
{
	return nil;
}

@end

@implementation CSVFileParser (Preferences)

+ (void) initialize
{
    if( self == [CSVFileParser class])
    {
        NSDictionary *encodings = [[NSUserDefaults standardUserDefaults] objectForKey:DEFS_ENCODING_FOR_FILES];
        if( encodings && [encodings isKindOfClass:[NSDictionary class]] )
        {
            encodingForFileName = [[NSMutableDictionary alloc] initWithDictionary:encodings];
        }
        else
        {
            encodingForFileName = [[NSMutableDictionary alloc] init];
        }
        _allowedEncodings = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:DEFAULT_ENCODING],
                             [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],
                             [NSNumber numberWithUnsignedInteger:NSUnicodeStringEncoding],
                             [NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding],
                             [NSNumber numberWithUnsignedInteger:NSMacOSRomanStringEncoding], nil];
        _allowedEncodingNames = [NSArray arrayWithObjects:@"<default>", @"UTF8", @"Unicode", @"Latin1", @"Mac", nil];
        _files = [NSMutableArray array];
    }
}

+ (void) saveEncodingForFiles
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if( encodingForFileName )
    {
        [defaults setObject:encodingForFileName forKey:DEFS_ENCODING_FOR_FILES];
        [defaults synchronize];
    }
}

+ (void) setFileEncoding:(NSStringEncoding)encoding forFile:(NSString *)fileName
{
    if( fileName != nil)
    {
        [encodingForFileName setObject:[NSNumber numberWithUnsignedInteger:encoding]
                                forKey:fileName];
        [self saveEncodingForFiles];
    }
}

+ (void) removeFileEncodingForFile:(NSString *) fileName
{
    [encodingForFileName removeObjectForKey:fileName];
    [self saveEncodingForFiles];
}

+ (NSStringEncoding) getEncodingForFile:(NSString *)fileName
{
    NSNumber *encoding = [encodingForFileName objectForKey:fileName];
    if( encoding && [encoding unsignedIntegerValue] != DEFAULT_ENCODING)
    {
        return [encoding unsignedIntegerValue];
    }
    else
    {
        return [CSVPreferencesController encoding];
    }
}

+ (NSUInteger) getEncodingSettingForFile:(NSString *)fileName
{
    NSNumber *encoding = [encodingForFileName objectForKey:fileName];
    if( encoding )
    {
        return [encoding unsignedIntegerValue];
    }
    else
    {
        return DEFAULT_ENCODING;
    }
}

@end



