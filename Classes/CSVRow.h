//
//  CSVRow.h
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzyTableViewController.h"

#define VALUE_KEY @"valueKey"
#define COLUMN_KEY @"columnKey"

@class CSVFileParser;

@interface CSVRow : NSObject <OzyTableViewObject>
{
	NSString *_shortDescription;
	NSArray *_items;
	NSMutableArray *_fixedWidthItems;
	CSVFileParser *_fileParser;
	NSUInteger _rawDataPosition;
	NSString *_imageName;
}

@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) NSMutableArray *fixedWidthItems;
@property (nonatomic, assign) CSVFileParser *fileParser;
@property (nonatomic, assign) NSUInteger rawDataPosition;
@property (nonatomic, retain) NSString *imageName;

- initWithItemCapacity:(NSUInteger)itemCapacity;

- (NSString *) longDescriptionWithHiddenValues:(BOOL)includeHiddenValues;
- (NSMutableArray *) longDescriptionInArrayWithHiddenValues:(BOOL)includeHiddenValues;
- (NSArray *) columnsAndValues; 

+ (SEL) compareSelector;
@end
