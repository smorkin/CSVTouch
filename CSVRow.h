//
//  CSVRow.h
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OzymandiasAdditions.h"

#define VALUE_KEY @"valueKey"
#define COLUMN_KEY @"columnKey"

@class CSVFileParser;

@interface CSVRow : NSObject <OzyTableViewObject>
{
}

@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, retain) NSString *lowercaseShortDescription;
@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) NSMutableArray *fixedWidthItems;
@property (nonatomic, assign) CSVFileParser *fileParser;
@property (nonatomic, retain) NSString *imageName;

// For performance reasons, we have a bunch of pre-initialized format strings. When settings
// are changed, we need to redo those;
+ (void) refreshRowFormatStrings;


- initWithItemCapacity:(NSUInteger)itemCapacity;

- (NSString *) htmlDescriptionWithHiddenValues:(BOOL)includeHiddenValues;
// Call with YES for regular visible columns, NO for hidden columns
- (NSMutableArray *) longDescriptionInArray:(BOOL)useShownColumns;
- (NSArray *) columnsAndValues;

// NOTE! Requires both fileParser & items to have been set already. Also, make sure size of widths == items.count
- (void) createFixedWidthItemsUsingWidths:(int *)widths;

+ (SEL) compareSelector;
@end
