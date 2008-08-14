//
//  CSVRow.h
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

#define VALUE_KEY @"valueKey"
#define COLUMN_KEY @"columnKey"

@class CSVFileParser;

@interface CSVRow : NSObject
{
	NSString *_shortDescription;
	NSArray *_items;
	CSVFileParser *_fileParser;
	NSUInteger _rawDataPosition;
}

@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, retain) NSArray *items;
@property (nonatomic, assign) CSVFileParser *fileParser;
@property (nonatomic, assign) NSUInteger rawDataPosition;

- (NSString *) longDescription;
- (NSMutableArray *) longDescriptionInArray;
- (NSArray *) columnsAndValues; 

- (NSComparisonResult) compareShort:(CSVRow *)r;

@end
