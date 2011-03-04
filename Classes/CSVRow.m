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

#define ITEM_SEPARATOR "‧"

@implementation CSVRow

@synthesize shortDescription = _shortDescription;
@synthesize items = _items;
@synthesize fixedWidthItems = _fixedWidthItems;
@synthesize fileParser = _fileParser;
@synthesize rawDataPosition = _rawDataPosition;
@synthesize imageName = _imageName;

- (NSComparisonResult) compareShort:(CSVRow *)row
{
	return [self.shortDescription compare:row.shortDescription options:sortingMask];
}

- (NSComparisonResult) compareItems:(CSVRow *)row
{
	NSUInteger columnsShown = [[[CSVDataViewController sharedInstance] importantColumnIndexes] count];
	int *importantColumnIndexes = [[CSVDataViewController sharedInstance] rawColumnIndexes];
	
	NSUInteger i;
	NSComparisonResult r;
	for( i = 0 ; i < columnsShown ; i++ )
	{
		r = [[self.items objectAtIndex:importantColumnIndexes[i]] compare:[row.items objectAtIndex:importantColumnIndexes[i]] options:sortingMask];
		if( r != NSOrderedSame )
			return r;
	}
	return NSOrderedSame;
}

+ (SEL) compareSelector
{
	if( [CSVPreferencesController useCorrectSorting] )
		return @selector(compareItems:);
	else
		return @selector(compareShort:);
}

static NSMutableArray *formatsStrings = nil;

+ (NSString *) wordSeparator
{
	return (([CSVPreferencesController useFixedWidth] || [CSVPreferencesController blankWordSeparator])
			? @" " : @"‧");
}

+ (void) initialize
{
	if( formatsStrings == nil )
	{
		NSString *separator = [CSVRow wordSeparator];
		formatsStrings = [[NSMutableArray alloc] initWithCapacity:20];
		for( NSInteger numberOfWords = 2 ; numberOfWords <= 20 ; numberOfWords++ )
		{
			NSMutableString *s = [NSMutableString string];
			for( NSInteger i = 0 ; i < numberOfWords ; i++ )
			{
				[s appendString:@"%@"];
				if( i < numberOfWords-1 )
					[s appendString:separator];
			}
			[formatsStrings addObject:s];
		}
	}
}


+ (NSString *) concatenateWords:(NSArray *)words
				   usingIndexes:(int *)indexes
						  count:(int)indexCount
{
	if( indexCount <= 0 )
		return @"";
	else if( indexCount > [words count] )
		return nil;
	
//	if( indexCount  == 1 )
//		return [words objectAtIndex:indexes[0]];
//	else if( indexCount <= 19 )
//		return [NSString stringWithFormat:formatsStrings[indexCount-2]];
//	else
//	{
//		NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:200] autorelease];
//		for( NSUInteger i = 0 ; i < indexCount ; i++ )
//			[s appendFormat:@"%@‧", [words objectAtIndex:indexes[i]]];
//		return s;
//	}
	
	
		
	switch(indexCount)
	{
		case 1:
			return [words objectAtIndex:indexes[0]];
		case 2:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]]];
		case 3:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]]];			
		case 4:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]]];			
		case 5:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]]];			
		case 6:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]]];			
		case 7:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]]];	
		case 8:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
					[words objectAtIndex:indexes[0]], 
					[words objectAtIndex:indexes[1]], 
					[words objectAtIndex:indexes[2]], 
					[words objectAtIndex:indexes[3]], 
					[words objectAtIndex:indexes[4]],			
					[words objectAtIndex:indexes[5]],			
					[words objectAtIndex:indexes[6]],			
					[words objectAtIndex:indexes[7]]];	
		case 9:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
		case 17:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
					[words objectAtIndex:indexes[15]],			
					[words objectAtIndex:indexes[16]]];			
		case 18:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
					[words objectAtIndex:indexes[15]],			
					[words objectAtIndex:indexes[16]],			
					[words objectAtIndex:indexes[17]]];			
		case 19:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
					[words objectAtIndex:indexes[15]],			
					[words objectAtIndex:indexes[16]],			
					[words objectAtIndex:indexes[17]],			
					[words objectAtIndex:indexes[18]]];			
		case 20:
			return [NSString stringWithFormat:[formatsStrings objectAtIndex:indexCount-2], 
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
					[words objectAtIndex:indexes[15]],			
					[words objectAtIndex:indexes[16]],			
					[words objectAtIndex:indexes[17]],			
					[words objectAtIndex:indexes[18]],			
					[words objectAtIndex:indexes[19]]];			
		default:
		{
			NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:200] autorelease];
			for( NSUInteger i = 0 ; i < indexCount ; i++ )
				[s appendFormat:@"%@%@", [words objectAtIndex:indexes[i]],
				 [CSVRow wordSeparator]];
			return s;
		}
	}
}

- (NSArray *) columnsAndValues
{
	NSMutableArray *array = [NSMutableArray array];
	
	// First add sorted column data
	NSArray *importantColumnIndexes = [[CSVDataViewController sharedInstance] importantColumnIndexes];
	NSArray *availableColumnNames = [self.fileParser availableColumnNames];
	for( NSNumber *index in importantColumnIndexes )
	{
		[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  [self.items objectAtIndex:[index intValue]], VALUE_KEY,
						  [availableColumnNames objectAtIndex:[index intValue]], COLUMN_KEY,
						  nil]];
	}
	
	// Then add other data
	if( [importantColumnIndexes count] < [availableColumnNames count] )
	{
		for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
		{
			if( ![importantColumnIndexes containsObject:[NSNumber numberWithInt:i]] )
			{
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [self.items objectAtIndex:i], VALUE_KEY,
								  [availableColumnNames objectAtIndex:i], COLUMN_KEY,
								  nil]];
			}				
		}
	}
	
	return array;
}

- (NSMutableArray *) longDescriptionInArrayWithHiddenValues:(BOOL)includeHiddenValues
{
	NSMutableArray *array = [NSMutableArray array];
	
	// First add sorted column data
	NSArray *importantColumnIndexes = [[CSVDataViewController sharedInstance] importantColumnIndexes];
	NSArray *availableColumnNames = [self.fileParser availableColumnNames];
	for( NSNumber *index in importantColumnIndexes )
	{
		NSMutableString *s = [NSMutableString stringWithFormat:@"%@: %@", 
					   [availableColumnNames objectAtIndex:[index intValue]], 
					   [self.items objectAtIndex:[index intValue]]];
		[s replaceOccurrencesOfString:@"\n" 
						   withString:@" " 
							  options:0
								range:NSMakeRange(0, [s length])];				
		[array addObject:s];
	}
	
	// Then add other data
	if( includeHiddenValues )
	{
		if( [importantColumnIndexes count] < [availableColumnNames count] )
		{
			NSMutableArray *otherColumns = [NSMutableArray array];
			for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
			{
				if( ![importantColumnIndexes containsObject:[NSNumber numberWithInt:i]] )
				{
					NSMutableString *s = [NSMutableString stringWithFormat:@"%@: %@",
										  [availableColumnNames objectAtIndex:i],
										  [self.items objectAtIndex:i]];
					[s replaceOccurrencesOfString:@"\n" 
									   withString:@" " 
										  options:0
											range:NSMakeRange(0, [s length])];				
					[otherColumns addObject:s];
				}				
			}
			//		[otherColumns sortUsingSelector:@selector(compare:)];
			[array addObjectsFromArray:otherColumns];
		}
	}
	return array;
}

- (NSString *) shortDescription
{
	if( !_shortDescription )
	{
		if( [CSVPreferencesController definedFixedWidths] )
			self.shortDescription = [CSVRow concatenateWords:self.fixedWidthItems 
												usingIndexes:[[CSVDataViewController sharedInstance] rawColumnIndexes]
													   count:[[[CSVDataViewController sharedInstance] importantColumnIndexes] count]];
		else 
			self.shortDescription = [CSVRow concatenateWords:self.items 
												usingIndexes:[[CSVDataViewController sharedInstance] rawColumnIndexes]
													   count:[[[CSVDataViewController sharedInstance] importantColumnIndexes] count]];
	}
	return _shortDescription;
}

- (NSString *) longDescriptionWithHiddenValues:(BOOL)includeHiddenValues
{
	// First add sorted column data
	NSMutableString *s = [NSMutableString stringWithCapacity:200];
	NSArray *importantColumnIndexes = [[CSVDataViewController sharedInstance] importantColumnIndexes];
	NSArray *availableColumnNames = [self.fileParser availableColumnNames];
	for( NSNumber *index in importantColumnIndexes )
	{
		[s appendFormat:@"%@: %@\n", 
		 [availableColumnNames objectAtIndex:[index intValue]], 
		 [self.items objectAtIndex:[index intValue]]];
	}
	
	// Then add other data
	if( includeHiddenValues )
	{
		if( [importantColumnIndexes count] < [availableColumnNames count] )
		{
			[s appendString:@"____________________\n"];
			for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
			{
				if( ![importantColumnIndexes containsObject:[NSNumber numberWithInt:i]] )
					[s appendFormat:@"%@: %@\n",
					 [availableColumnNames objectAtIndex:i],
					 [self.items objectAtIndex:i]];
			}
		}
	}
			
	return s;
}

// OzyTableViewObject protocol
- (NSString *) tableViewDescription
{
	return [self shortDescription];
}

- (NSString *) imageName
{
	return [NSString stringWithFormat:@"%@.png", _imageName];
}

- (NSString *) emptyImageName
{
	if( self.fileParser.iconIndex != NSNotFound )
		return @"empty.png";
	else
		return nil;
}

- initWithItemCapacity:(NSUInteger)itemCapacity
{
	self = [super init];
	_fixedWidthItems = [[NSMutableArray alloc] initWithCapacity:itemCapacity];
	return self;
}

- (void) dealloc
{
	self.items = nil;
	self.shortDescription = nil;
	self.fileParser = nil;
	self.imageName = nil;
	[_fixedWidthItems release];
	[super dealloc];
}

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//	self = [super init];
//	
//	self.shortDescription = [[aDecoder decodeObjectForKey:@"shortDescription"] retain];
//	self.items = [[aDecoder decodeObjectForKey:@"items"] retain];
//    return self;	
//}
//
//- (void)encodeWithCoder:(NSCoder *)coder
//{
//	if( _shortDescription )
//		[coder encodeObject:_shortDescription forKey:@"shortDescription"];
//	if( _items )
//		[coder encodeObject:_items forKey:@"items"];
//}

@end

