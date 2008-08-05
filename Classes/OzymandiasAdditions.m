//
//  OzymandiasAdditions.m
//  CSV Touch
//
//  Created by Simon Wigzell on 17/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzymandiasAdditions.h"


@implementation NSString (OzymandiasExtension)
- (BOOL) containsDigit
{
	return [self rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].length > 0;
}

- (BOOL) hasSubstring:(NSString *)s
{
	NSRange range = [self rangeOfString:s];
	return range.location != NSNotFound;
}

- (NSComparisonResult) numericSensitiveCompare:(NSString *)s
{
	return [self compare:s options:NSNumericSearch];
}

@end

@implementation NSIndexPath (OzymandiasExtension)

#define ROW_KEY @"row"
#define SECTION_KEY @"section"

+ (NSIndexPath *) indexPathWithDictionary:(NSDictionary *)d
{
	return [self indexPathForRow:[[d objectForKey:ROW_KEY] intValue] inSection:[[d objectForKey:SECTION_KEY] intValue]];
}

- (NSDictionary *) dictionaryRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:self.row], ROW_KEY,
			[NSNumber numberWithInt:self.section], SECTION_KEY,
			nil];
}

@end

@implementation UITableView (OzymandiasExtension)

- (void) scrollToTopWithAnimation:(BOOL)animate
{
	if( [[self dataSource] tableView:self numberOfRowsInSection:0] > 0 )
		[self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
					atScrollPosition:UITableViewScrollPositionTop
							animated:animate];
}

@end
