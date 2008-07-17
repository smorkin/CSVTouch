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
