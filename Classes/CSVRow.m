//
//  CSVRow.m
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVRow.h"
#import "OzyTableViewController.h"
#import "CSVPreferencesController.h"
#import "CSVDataViewController.h"
#import "CSVFileParser.h"

@implementation CSVRow

@synthesize shortDescription = _shortDescription;
@synthesize items = _items;
@synthesize fileParser = _fileParser;
@synthesize rawDataPosition = _rawDataPosition;

- (NSComparisonResult) compareShort:(CSVRow *)row
{
	return [self.shortDescription compare:row.shortDescription options:sortingMask];
	
//	NSComparisonResult r;
//	NSArray *otherItems = row.items;
//	for( NSUInteger i = 0 ; i < [_items count] ; i++ )
//	{
//		if( (r = [[_items objectAtIndex:i] compare:[otherItems objectAtIndex:i] options:sortingMask]) != NSOrderedSame )
//			return r;
//	}
//	return NSOrderedSame;
}

+ (NSString *) concatenateWords:(NSArray *)words
				   usingIndexes:(int *)indexes
						  count:(int)indexCount
{
	if( indexCount <= 0 )
		return @"";
	
	switch(indexCount)
	{
		case 1:
			return [words objectAtIndex:indexes[0]];
		case 2:
			return [NSString stringWithFormat:@"%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]]];
		case 3:
			return [NSString stringWithFormat:@"%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]]];			
		case 4:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]]];			
		case 5:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]]];			
		case 6:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]]];			
		case 7:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]]];	
		case 8:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]]];	
		case 9:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],			
					[words objectAtIndex:indexes[8]]];	
		case 10:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]]];			
		case 11:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],
					[words objectAtIndex:indexes[10]]];			
		case 12:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],			
					[words objectAtIndex:indexes[10]],			
					[words objectAtIndex:indexes[11]]];			
		case 13:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],			
					[words objectAtIndex:indexes[10]],			
					[words objectAtIndex:indexes[11]],			
					[words objectAtIndex:indexes[12]]];			
		case 14:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],			
					[words objectAtIndex:indexes[10]],			
					[words objectAtIndex:indexes[11]],			
					[words objectAtIndex:indexes[12]],			
					[words objectAtIndex:indexes[13]]];			
		case 15:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],			
					[words objectAtIndex:indexes[10]],			
					[words objectAtIndex:indexes[11]],			
					[words objectAtIndex:indexes[12]],			
					[words objectAtIndex:indexes[13]],			
					[words objectAtIndex:indexes[14]]];			
		case 16:
			return [NSString stringWithFormat:@"%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@‧%@", 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]],		
					[words objectAtIndex:indexes[8]],			
					[words objectAtIndex:indexes[9]],			
					[words objectAtIndex:indexes[10]],			
					[words objectAtIndex:indexes[11]],			
					[words objectAtIndex:indexes[12]],			
					[words objectAtIndex:indexes[13]],			
					[words objectAtIndex:indexes[14]],			
					[words objectAtIndex:indexes[15]]];			
		default:
		{
			NSMutableString *s = [[NSMutableString alloc] initWithCapacity:200];
			for( NSUInteger i = 0 ; i < [words count] ; i++ )
				[s appendFormat:@"%@‧", [words objectAtIndex:indexes[i]]];
			return s;
		}
	}
}

- (NSString *) shortDescription
{
	if( !_shortDescription )
	{
		self.shortDescription = [CSVRow concatenateWords:self.items 
											usingIndexes:[[CSVDataViewController sharedInstance] rawColumnIndexes]
												   count:[[[CSVDataViewController sharedInstance] columnIndexes] count]];
	}
	return _shortDescription;
}

- (NSString *) longDescription
{
	// First add sorted column data
	NSMutableString *s = [NSMutableString stringWithCapacity:200];
	NSArray *columnIndexes = [[CSVDataViewController sharedInstance] columnIndexes];
	NSArray *availableColumnNames = [self.fileParser availableColumnNames];
	for( NSNumber *index in columnIndexes )
	{
		[s appendFormat:@"%@: %@\n", 
		 [availableColumnNames objectAtIndex:[index intValue]], 
		 [self.items objectAtIndex:[index intValue]]];
	}
	
	// Then add other data
	if( [columnIndexes count] < [availableColumnNames count] )
	{
		[s appendString:@"____________________\n"];
		for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
		{
			if( ![columnIndexes containsObject:[NSNumber numberWithInt:i]] )
				[s appendFormat:@"%@: %@\n",
				[availableColumnNames objectAtIndex:i],
				[self.items objectAtIndex:i]];
		}
	}
			
	return s;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	self.shortDescription = [[aDecoder decodeObjectForKey:@"shortDescription"] retain];
	self.items = [[aDecoder decodeObjectForKey:@"items"] retain];
    return self;	
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if( _shortDescription )
		[coder encodeObject:_shortDescription forKey:@"shortDescription"];
	if( _items )
		[coder encodeObject:_items forKey:@"items"];
}

@end

@interface CSVRow (OzyTableViewProtocol) <OzyTableViewObject>
@end

@implementation CSVRow (OzyTableViewProtocol)

- (NSString *) tableViewDescription
{
	return [self shortDescription];
}

@end

