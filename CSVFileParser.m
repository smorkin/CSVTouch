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
#import "FilesViewController.h"
#import "csv.h"
#import "parseCSV.h"
#import "OzymandiasAdditions.h"

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
@property (nonatomic) unichar usedDelimiter;
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

+ (void) removeAllFiles
{
    [_files removeAllObjects];
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

+ (CSVFileParser *) existingParserForName:(NSString *)name
{
    for( CSVFileParser *file in _files )
    {
        // Do not use -isEqualToString! This gives wrong results due to using literal Unicode compare which is bad for us since strings might come from both file system names & URL paths
        // Also, file name contains .csvtouch
        if( [name localizedCompare:[[file fileName] stringByDeletingPathExtension]] == NSOrderedSame )
        {
            return file;
        }
    }
    return nil;
}
+ (void) removeFileWithName:(NSString *)name
{
    for( CSVFileParser *oldFile in _files )
    {
        // Do not use -isEqualToString! This gives wrong results due to using literal Unicode compare which is bad for us since strings might come from both file system names & URL paths
        if( [name localizedCompare:[oldFile fileName]] == NSOrderedSame )
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
        if( [[fp.URL decomposedStringWithCanonicalMapping] isEqualToString:[URL decomposedStringWithCanonicalMapping]] )
            return YES;
    }
    return NO;
}

static NSTimer *_resetDownloadFlagsTimer;

+ (void) resetClearingOfDownloadFlagsTimer
{
    [_resetDownloadFlagsTimer invalidate];
    _resetDownloadFlagsTimer = [NSTimer timerWithTimeInterval:60*60 // 1h
                                                      repeats:NO
                                                        block:^(NSTimer *timer)
                                {
                                    for( CSVFileParser *file in _files)
                                    {
                                        file.hasFailedToDownload = FALSE;
                                        file.hasBeenDownloaded = FALSE;
                                    }
                                    [[FilesViewController sharedInstance].tableView reloadData];
                                }];
    [[NSRunLoop currentRunLoop] addTimer:_resetDownloadFlagsTimer forMode:NSDefaultRunLoopMode];
}

#define DEFS_COLUMN_NAMES @"defaultColumnNames"

+ (void) saveColumnNames
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for( CSVFileParser *parser in self.files)
    {
        // Note that parsers don't have shown column names configured unless they've been shown in UI ->
        // We must take from parser if exists, otherwise from old defaults
        if( [parser.shownColumnNames count] > 0){
            [d setObject:parser.shownColumnNames forKey:parser.fileName];
        }
        else{
            [d setObject:[self shownColumnsFromDefaults:parser] forKey:parser.fileName];
        }
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
    return [NSMutableArray array];
}

+ (NSArray *) allowedDelimiters
{
    static NSArray *delimiters = nil;
    
    if( !delimiters )
        delimiters = [NSArray arrayWithObjects:@",", @";", @".", @"|", @" ", @"\t", nil];
    
    return delimiters;
}

- (BOOL) downloadedLocally
{
    return !self.URL || [self.URL isEqualToString:@""];
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
- (NSMutableArray<CSVRow *> *) itemsWithResetShortdescriptions:(BOOL)reset
{
	if( reset )
		[self invalidateShortDescriptions];
	return self.parsedItems;
}

- (void) sortItems
{
    [self.parsedItems sortUsingSelector:[CSVRow compareSelector]];
    self.hasBeenSorted = YES;
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
                    {
						columnWidths[columnNumber++] = [width intValue];
                    }
					[tmp removeObjectAtIndex:0];
				}
				numberOfRows = [tmp count];
				NSMutableArray *words;
				for( NSUInteger rawrow = 0 ; rawrow < numberOfRows ; rawrow++ )
				{
					words = [tmp objectAtIndex:rawrow];
					if( [words count] != numberOfColumns )
					{
                        if( !self.problematicRow){
                            self.problematicRow = [NSString stringWithFormat:@"Found %lu values, expected %lu for row %lu; row data: %@",
                                                   (unsigned long)[words count],
                                                   (unsigned long)numberOfColumns,
                                                   (unsigned long)rawrow+1,
                                                   words];
                        }
					}
					else
					{
						CSVRow *csvrow = [[CSVRow alloc] initWithItemCapacity:[self.columnNames count]];
                        csvrow.fileParser = self;
						if( self.iconIndex != NSNotFound )
						{
							csvrow.imageName = [words objectAtIndex:self.iconIndex];
							[words removeObjectAtIndex:self.iconIndex];
						}
						csvrow.items = words;
                        [csvrow createFixedWidthItemsUsingWidths:columnWidths];
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
					if(!testing && wordNumber < *foundColumns )
					{
						for( int i = 0 ; i < *foundColumns - wordNumber ; i++ )
							[words addObject:@""];
					}
					else
					{
						if( !testing )
						{
                            if( !self.problematicRow){
                                self.problematicRow = [NSString stringWithFormat:@"Found %d values, expected %d for row %d:\n%@",
                                                       wordNumber,
                                                       *foundColumns,
                                                       numberOfRows,
                                                       line];
                            }
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
                        csvrow.fileParser = self;
						if( self.iconIndex != NSNotFound )
						{
							csvrow.imageName = [words objectAtIndex:self.iconIndex];
							[words removeObjectAtIndex:self.iconIndex];
						}
						csvrow.items = words;
                        [csvrow createFixedWidthItemsUsingWidths:columnWidths];
                        [self.parsedItems addObject:csvrow];
                    }
                }
            }
            else
            {
                if( !self.problematicRow){ // Pick first problematic row
                    self.problematicRow = [NSString stringWithFormat:@"Problem parsing row %d: %@", numberOfRows, line];
                }
            }
            numberOfRows++;
        }
    }
        
    if( columnWidths != NULL )
    {
        free( columnWidths);
    }
	return TRUE;
}

- (unichar) delimiter
{
	if( [CSVPreferencesController smartDelimiter] )
	{
		int foundColumns;
		int bestResult = 0;
		unichar bestDelimiter = ',';
		for( NSString *testDelimiter in [CSVFileParser allowedDelimiters] )
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
	self.usedDelimiter = [self delimiter];
	
	// Parse file
	[self parse:_rawString
	  delimiter:self.usedDelimiter
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
    self.rawShownColumnIndexes = NULL;
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
    [CSVFileParser removeFile:self];
    
}

- (NSString *) fileName
{
	return [[self.filePath lastPathComponent] decomposedStringWithCanonicalMapping];
}

- (NSUInteger) stringLength
{
	return [_rawString length];
}

+ (CSVFileParser *) addParserWithRawData:(NSData *)data forFilePath:(NSString *)path
{
    CSVFileParser *cfp = [[self alloc] initWithRawData:data filePath:path];
    [self addParser:cfp];
    return cfp;
}

- (NSData *) fileRawData
{
    return _rawData;
}

- (void) saveToFile
{
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:_rawData, FILEPARSER_RAW_DATA,
					   self.URL, FILEPARSER_URL,
					   self.downloadDate, FILEPARSER_DOWNLOAD_DATE,
					   [NSNumber numberWithBool:self.hideAddress], FILEPARSER_HIDE_ADDRESS,
					   nil];
    if(	[d writeToFile:self.filePath atomically:YES])
    {
        // Set the file path to the actual string you get back when looking at the file in the file system. Sounds weird, but if you e.g. used an http URL with file name containing "Ö" and write using this string as path to the file system and you then read the file name, you'll still get "Ö" (naturally) but it won't compare equal to the original "Ö"...
    }
}

- (NSString *) readableUsedDelimiter
{
    if( self.usedDelimiter == '\t')
        return @"<tab>";
    else if( self.usedDelimiter == ' ' )
        return @"<space>";
    else
        return [NSString stringWithFormat:@"%C", self.usedDelimiter];
}

- (NSString *) parseErrorString
{
    NSMutableString *s = [NSMutableString string];
    
    // What type of problem?
    if( [self.rawString length] == 0 )
    {
        [s appendString:@"Couldn't read the file using the selected encoding."];
    }
    else
    {
        [s appendFormat:@"Error reading file:\n\nUsed separator: %@\n\nFound number of columns using separator:%lu\n\nFound rows using separator:%lu",
         [self readableUsedDelimiter],
         (unsigned long)[[self columnNames] count],
         (unsigned long)[[self itemsWithResetShortdescriptions:NO] count]];
        if( [CSVPreferencesController keepQuotes] && [self.problematicRow hasSubstring:@"\""])
            [s appendString:@"\n\nTry switching off the \"Keep Quotes\"-setting."];
        if( self.problematicRow && ![self.problematicRow isEqualToString:@""] ){
            [s appendFormat:@"\n\nPotentially first problematic row:\n\n%@\n\n",
             self.problematicRow];
        }
        else
        {
            [s appendFormat:@"\n\nFile read when using the selected encoding:\n\n%@", self.rawString];
        }
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
        {
            if( [usedColumn isEqualToString:[self.columnNames objectAtIndex:i]] )
            {
                [self.shownColumnIndexes addObject:[NSNumber numberWithUnsignedInteger:i]];
                break;
            }
        }
    }
    // Here we can run into a problem: Normally sizeof(shownColumnNames) = sizeof(shownColumnIndexes).
    // But if we e.g. have changed encoding used, the previously saved column names to show might no longer
    // exist among the available column names. If this happens, let's just redo
    if( [self.shownColumnIndexes count] != [self.shownColumnNames count])
    {
        self.shownColumnNames = [self.columnNames mutableCopy];
        [self updateRawColumnIndexes];
    }
    else
    {
        self.rawShownColumnIndexes = malloc(sizeof(int) * [self.shownColumnIndexes count]);
        for( int i = 0 ; i < [self.shownColumnIndexes count] ; i++ )
        {
            self.rawShownColumnIndexes[i] = [[self.shownColumnIndexes objectAtIndex:i] intValue];
        }
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
            self.shownColumnNames = [self.columnNames mutableCopy];
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
    self.shownColumnNames = [self.columnNames mutableCopy];
    [self updateRawColumnIndexes];
    self.hasBeenSorted = FALSE;
}

- (BOOL) hiddenColumnsExist
{
    return [self.shownColumnIndexes count] < [self.columnNames count];
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
    if( self.hasFailedToDownload)
        return [NSString stringWithFormat:@"‒  %@", [self defaultTableViewDescription]];
	else if( self.hasBeenDownloaded )
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
    if( !fileName || [fileName isEqualToString:@""]){
        return DEFAULT_ENCODING;
    }
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



