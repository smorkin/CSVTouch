#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <stdbool.h>

#import "parseCSV.h"

/* Macros for determining if the given character is End Of Line or not */
#define EOL(x) ((*(x) == '\r' || *(x) == '\n') && *(x) != '\0')
#define NOT_EOL(x) (*(x) != '\0' && *(x) != '\r' && *(x) != '\n')

/*
 * replacement for strstr() which does only check every char instead
 * of complete strings
 * Warning: Do not call it with haystack == NULL || needle == NULL!
 *
 */
static char *cstrstr(const char *haystack, const char needle) {
	char *it = (char*)haystack;
	while (*it != '\0') {
		if (*it == needle)
			return it;
		it++;
	}
	return NULL;
}

@implementation CSVParser

@synthesize string = _string;

/*
 * Copies a string without beginning- and end-quotes if there are
 * any and returns the string
 *
 */
-(NSString*)parseString:(char*)textp withLastStop:(char*)laststop {
	int stringSize = (int)(textp - laststop);
	if (*laststop == '\"' && *(laststop+1) != '\0' && *(laststop + stringSize - 1) == '\"') {
		laststop++;
		stringSize -= 2;
	}
	NSMutableString *tempString = [[[NSMutableString alloc] initWithBytes:(const void *)laststop
                                                                   length:stringSize
                                                                 encoding:encoding] autorelease];
	[tempString replaceOccurrencesOfString:@"\"\""
                                withString:@"\""
                                   options:0
                                     range:NSMakeRange(0, [tempString length])];
	return tempString;
}

-(id)init {
	self = [super init];
	if (self) {
		// Set default bufferSize
		bufferSize = 2048;
		// Set fileHandle to an invalid value
		fileHandle = 0;
		// Set delimiter to 0
		delimiter = ',';
		// Set default encoding; should be one which works fine w c strings
		encoding = NSUTF8StringEncoding;
	}
	return self;
}

- (void) dealloc
{
	self.string = nil;
	
	[super dealloc];
}

- (void) setBufferSize:(int)newSize
{
	bufferSize = newSize;
}

/*
 * Parses the CSV-file with the given filename and stores the result in a
 * NSMutableArray.
 *
 */
-(NSMutableArray*)parseFile
{
	NSMutableArray *csvLine = [NSMutableArray array];
	NSMutableArray *csvContent = [NSMutableArray array];
	unsigned int quoteCount = 0;
	const char *allData = [_string cStringUsingEncoding:encoding];
	if (allData == NULL )
		return csvContent;
	int length = (int)strlen(allData);
	[self setBufferSize:length+1];
	char *textp, *laststop, *lineBeginning;
	
	textp = (char*)allData;
	
	while (*textp != '\0')
	{
        //		if (strlen(textp) > 0)
		{
			// This is data
			laststop = textp;
			lineBeginning = textp;
			
			// Parsing is splitted in parts till EOL
			while (NOT_EOL(textp) || (*textp != '\0' && (quoteCount % 2) != 0)) {
				// If we got two quotes and a delimiter before and after, this is an empty value
				if (	*textp == '\"' &&
					*(textp+1) == '\"') {
					// we'll just skip this, but firstly check if it's an empty value
					if (	(textp > (const char*)allData) &&
						*(textp-1) == delimiter &&
						*(textp+2) == delimiter) {
						[csvLine addObject: @""];
					}
					textp++;
				} else if (*textp == '\"')
					quoteCount++;
				else if (*textp == delimiter && (quoteCount % 2) == 0) {
					// There is a delimiter which is not between an unmachted pair of quotes?
					[csvLine addObject: [self parseString:textp withLastStop:laststop]];
					laststop = textp + 1;
				}
				
				// Go to the next character
				textp++;
			}
			
			if (laststop == textp && *(textp-1) == delimiter) {
				[csvLine addObject:@""];
				if ((int)(allData + bufferSize - textp) > 0) {
					lineBeginning = textp + 1;
					[csvContent addObject: csvLine];
				}
				csvLine = [NSMutableArray array];
			}
			if (laststop != textp && (quoteCount % 2) == 0) {
				[csvLine addObject: [self parseString:textp withLastStop:laststop]];
				
				if ((int)(allData + bufferSize - textp) > 0) {
					lineBeginning = textp + 1;
					[csvContent addObject: csvLine];
				}
				csvLine = [NSMutableArray array];
			}
			if ((*textp == '\0' || (quoteCount % 2) != 0) && lineBeginning != textp) {
				csvLine = [NSMutableArray array];
			}
		}
		
		while (EOL(textp))
			textp++;
	}
	return csvContent;
}

-(char)delimiter {
	return delimiter;
}

-(void)setDelimiter:(char)newDelimiter {
	delimiter = newDelimiter;
}

-(void)setEncoding:(NSStringEncoding)newEncoding {
	encoding = newEncoding;
}
@end
