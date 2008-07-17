//
//  CSVRow.h
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSVFileParser;

@interface CSVRow : NSObject <NSCoding>
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

- (NSComparisonResult) compareShort:(CSVRow *)r;

@end
