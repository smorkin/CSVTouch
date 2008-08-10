/*
 * CSV Parser
 * (c) 2007 Michael Stapelberg
 * http://michael.stapelberg.de/
 *
 * BSD License
 *
 */

#import <Foundation/Foundation.h>

@interface CSVParser:NSObject {
	int fileHandle;
	int bufferSize;
	char delimiter;
	NSStringEncoding encoding;
	NSString *_string;
}
-(id)init;
-(char)autodetectDelimiter;
-(char)delimiter;
-(void)setDelimiter:(char)newDelimiter;
-(NSMutableArray*)parseFile;
-(void)setEncoding:(NSStringEncoding)newEncoding;

@property (nonatomic, retain) NSString *string;

@end
