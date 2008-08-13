//
//  CSVFileParser.h
//  CSV Touch
//
//  Created by Simon Wigzell on 03/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzyTableViewController.h"

@interface CSVFileParser : NSObject {
	NSMutableArray *_parsedItems;
	NSMutableArray *_columnNames;
	NSData *_rawData;
	NSString *_rawString;
	NSString *_filePath;
	NSString *_URL;
	NSString *_problematicRow;
	int _droppedRows;
	unichar _usedDelimiter;
	BOOL _hasBeenParsed;
	BOOL _hasBeenSorted;
}

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, readonly) NSString *rawString;
@property (nonatomic, readonly) unichar usedDelimiter;
@property (nonatomic, readonly) NSString *problematicRow;
@property (nonatomic, readonly) int droppedRows;
@property (nonatomic, assign) BOOL hasBeenSorted;
@property (nonatomic, assign) BOOL hasBeenParsed;

+ (CSVFileParser *) parserWithFile:(NSString *)path;
- (void) saveToFile;

- (id) initWithRawData:(NSData *)d;

- (void) parseIfNecessary;
- (void) reparseIfParsed;

- (NSArray *) availableColumnNames;
- (NSMutableArray *) itemsWithResetShortdescriptions:(BOOL)reset; // Note that a caller for performance reasons can resort these, but nothing else

- (NSString *) fileName;
- (NSUInteger) stringLength;

- (unichar) delimiter;

@end

@interface CSVFileParser (OzyTableViewProtocol) <OzyTableViewObject>
@end

