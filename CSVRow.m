//
//  CSVRow.m
//  CSV Touch
//
//  Created by Simon Wigzell on 02/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "CSVRow.h"
#import "CSVPreferencesController.h"
#import "CSVFileParser.h"

#define ITEM_SEPARATOR "‧"

@implementation CSVRow

- (NSComparisonResult) compareShort:(CSVRow *)row
{
    NSComparisonResult r = [self.shortDescription compare:row.shortDescription options:sortingMask];
    
    if( [CSVPreferencesController reverseItemSorting] )
    {
        if( r == NSOrderedAscending )
            return NSOrderedDescending;
        else if( r == NSOrderedDescending )
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }
    else
        return r;
}

- (NSComparisonResult) compareItems:(CSVRow *)row
{
	NSUInteger columnsShown = [self.fileParser.shownColumnNames count];
	int *importantColumnIndexes = self.fileParser.rawShownColumnIndexes;
	
	NSUInteger i;
	NSComparisonResult r;
	for( i = 0 ; i < columnsShown ; i++ )
	{
		r = [[self.items objectAtIndex:importantColumnIndexes[i]] compare:[row.items objectAtIndex:importantColumnIndexes[i]] options:sortingMask];
		if( r != NSOrderedSame )
        {
            if( [CSVPreferencesController reverseItemSorting] )
            {
                if( r == NSOrderedAscending )
                    return NSOrderedDescending;
                else
                    return NSOrderedAscending;
            }
            else
                return r;
        }
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
						  count:(NSUInteger)indexCount
{
	if( indexCount == 0 )
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
			NSMutableString *s = [[NSMutableString alloc] initWithCapacity:200];
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
	for( NSNumber *index in self.fileParser.shownColumnIndexes )
	{
		[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  [self.items objectAtIndex:[index intValue]], VALUE_KEY,
						  [self.fileParser.columnNames objectAtIndex:[index intValue]], COLUMN_KEY,
						  nil]];
	}
	
	// Then add other data
	if( [self.fileParser.shownColumnIndexes count] < [self.fileParser.columnNames count] )
	{
		for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
		{
			if( ![self.fileParser.shownColumnIndexes containsObject:[NSNumber numberWithUnsignedInteger:i]] )
			{
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [self.items objectAtIndex:i], VALUE_KEY,
								  [self.fileParser.columnNames objectAtIndex:i], COLUMN_KEY,
								  nil]];
			}				
		}
	}
	
	return array;
}

- (NSString *) descriptionForValueAtIndex:(NSUInteger)index
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"%@: %@",
                          [self.fileParser.columnNames objectAtIndex:index],
                          [self.items objectAtIndex:index]];
    [s replaceOccurrencesOfString:@"\n"
                       withString:@" "
                          options:0
                            range:NSMakeRange(0, [s length])];
    return s;
}

- (NSMutableArray *) longDescriptionInArray:(BOOL)useShownColumns
{
	NSMutableArray *array = [NSMutableArray array];
	
    if( useShownColumns){
        for( NSNumber *index in self.fileParser.shownColumnIndexes )
        {
            [array addObject:[self descriptionForValueAtIndex:[index intValue]]];
        }
    }
    else{
        for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
        {
            if( ![self.fileParser.shownColumnIndexes containsObject:[NSNumber numberWithUnsignedInteger:i]] )
            {
                [array addObject:[self descriptionForValueAtIndex:i]];
            }
        }
	}
	return array;
}

- (NSString *) shortDescription
{
	if( !_shortDescription )
	{
		if( [CSVPreferencesController definedFixedWidths] )
			_shortDescription = [CSVRow concatenateWords:self.fixedWidthItems
												usingIndexes:self.fileParser.rawShownColumnIndexes
													   count:[self.fileParser.shownColumnNames count]];
		else 
			_shortDescription = [CSVRow concatenateWords:self.items 
												usingIndexes:self.fileParser.rawShownColumnIndexes
													   count:[self.fileParser.shownColumnNames count]];
	}
	return _shortDescription;
}

- (NSString *) longDescriptionWithHiddenValues:(BOOL)includeHiddenValues
{
	// First add sorted column data
	NSMutableString *s = [NSMutableString stringWithCapacity:200];
	for( NSNumber *index in self.fileParser.shownColumnIndexes )
	{
		[s appendFormat:@"%@: %@\n", 
		 [self.fileParser.columnNames objectAtIndex:[index intValue]],
		 [self.items objectAtIndex:[index intValue]]];
	}
	
	// Then add other data
    if( includeHiddenValues && [self.fileParser hiddenColumnsExist])
	{
        [s appendString:@"____________________\n"];
        for( NSUInteger i = 0 ; i < [self.items count] ; i++ )
        {
            if( ![self.fileParser.shownColumnIndexes containsObject:[NSNumber numberWithUnsignedInteger:i]] )
                [s appendFormat:@"%@: %@\n",
                 [self.fileParser.columnNames objectAtIndex:i],
                 [self.items objectAtIndex:i]];
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
    if( _imageName){
        return [NSString stringWithFormat:@"%@.png", _imageName];
    }
    return nil;
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
	self.fixedWidthItems = [[NSMutableArray alloc] initWithCapacity:itemCapacity];
	return self;
}

- (void) dealloc
{
	self.items = nil;
	self.shortDescription = nil;
	self.fileParser = nil;
	self.imageName = nil;
    self.fixedWidthItems = nil;
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

