//
//  CSVFileParser.h
//  CSV Touch
//
//  Created by Simon Wigzell on 03/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzyTableViewController.h"

#define DEFAULT_ENCODING 0

@interface CSVFileParser : NSObject {
	NSMutableArray *_parsedItems;
	NSMutableArray *_columnNames;
	NSData *_rawData;
	NSString *_rawString;
	NSString *_filePath;
	NSString *_URL;
	NSDate *_downLoadDate;
	NSString *_problematicRow;
	int _droppedRows;
	unichar _usedDelimiter;
	BOOL _hasBeenParsed;
	BOOL _hasBeenSorted;
	BOOL _hasBeenDownloaded;
	NSUInteger _iconIndex;
	BOOL _hideAddress;
}

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, copy) NSDate *downloadDate;
@property (nonatomic, readonly) NSString *rawString;
@property (nonatomic, readonly) unichar usedDelimiter;
@property (nonatomic, copy) NSString *problematicRow;
@property (nonatomic, readonly) int droppedRows;
@property (nonatomic, assign) BOOL hasBeenSorted;
@property (nonatomic, assign) BOOL hasBeenParsed;
@property (nonatomic, assign) BOOL hasBeenDownloaded;
@property (nonatomic, assign) NSUInteger iconIndex;
@property (nonatomic, assign) BOOL hideAddress;

+ (CSVFileParser *) parserWithFile:(NSString *)path;
- (void) saveToFile;

- (id) initWithRawData:(NSData *)d filePath:(NSString *)filePath;

- (void) parseIfNecessary;
- (void) reparseIfParsed;

- (void) encodingUpdated;

- (NSArray *) availableColumnNames;
- (NSMutableArray *) itemsWithResetShortdescriptions:(BOOL)reset; // Note that a caller for performance reasons can resort these, but nothing else

- (NSString *) fileName;
- (NSUInteger) stringLength;

- (unichar) delimiter;

- (NSString *) parseErrorString;

+ (NSArray *) allowedFileEncodings; // NSUIntegers
+ (NSArray *) allowedFileEncodingNames;

@end

@interface CSVFileParser (OzyTableViewProtocol) <OzyTableViewObject>
- (NSString *) defaultTableViewDescription;
- (NSComparisonResult) compareFileName:(CSVFileParser *)fp;
@end

@interface CSVFileParser (Preferences)

+ (void) setFileEncoding:(NSStringEncoding)encoding forFile:(NSString *)fileName;
+ (void) removeFileEncodingForFile:(NSString *) fileName;
// Returns an actual good encoding
+ (NSStringEncoding) getEncodingForFile:(NSString *)fileName;
// Returns the actual setting, i.e. possibly DEFAULT_ENCODING
+ (NSUInteger) getEncodingSettingForFile:(NSString *)fileName;

@end


