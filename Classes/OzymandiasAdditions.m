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

- (BOOL) containsURL
{
	return [self hasSubstring:@"://"] || [self hasSubstring:@"mailto:"] || [self hasSubstring:@"tel:"];
}

- (BOOL) containsMailAddress
{
	return [self hasSubstring:@"@"];
}

- (BOOL) containsImageURL
{
	return ([self hasSubstring:@"http://"] || [self hasSubstring:@"https://"]) &&
	([self hasSuffix:@".jpg"] || [self hasSuffix:@".JPG"] ||
	 [self hasSuffix:@".jpeg"] || [self hasSuffix:@".JPEG"] ||
	 [self hasSuffix:@".png"] || [self hasSuffix:@".PNG"] ||
	 [self hasSuffix:@".gif"] || [self hasSuffix:@".GIF"]);
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

#define PIXELS_TO_COUNT_AS_SWIPE 5.0
#define PIXELS_TO_COUNT_AS_NONSWIPE 20.0

@implementation OzyTableView

- (void) dispatchSwipe:(UITouch *)finalTouch
{
	CGPoint endSwipePoint = [finalTouch locationInView:self];
	if( beginSwipePoint.x - endSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
	   fabs(beginSwipePoint.y - endSwipePoint.y) < PIXELS_TO_COUNT_AS_NONSWIPE &&
	   [self.delegate respondsToSelector:@selector(rightSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate rightSwipe:self];
	else if( endSwipePoint.x - beginSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
			fabs(beginSwipePoint.y - endSwipePoint.y) < PIXELS_TO_COUNT_AS_NONSWIPE &&
			[self.delegate respondsToSelector:@selector(leftSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate leftSwipe:self];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];

	UITouch *touch = [touches anyObject];
    NSUInteger numTaps = [touch tapCount];
	if( numTaps == 1 )
	{
		beginSwipePoint = [touch locationInView:self];
	}
	else
	{
		beginSwipePoint = CGPointZero;
	}	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
}

@end

@implementation OzyTextView

- (void) dispatchSwipe:(UITouch *)finalTouch
{
	CGPoint endSwipePoint = [finalTouch locationInView:self];
	if( beginSwipePoint.x - endSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
	   [self.delegate respondsToSelector:@selector(rightSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate rightSwipe:self];
	else if( endSwipePoint.x - beginSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
			[self.delegate respondsToSelector:@selector(leftSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate leftSwipe:self];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	UITouch *touch = [touches anyObject];
    NSUInteger numTaps = [touch tapCount];
	if( numTaps == 1 )
	{
		beginSwipePoint = [touch locationInView:self];
	}
	else
	{
		beginSwipePoint = CGPointZero;
	}	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
}

@end

@implementation OzyWebView

- (void) dispatchSwipe:(UITouch *)finalTouch
{
	CGPoint endSwipePoint = [finalTouch locationInView:self];
	if( beginSwipePoint.x - endSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
	   [self.delegate respondsToSelector:@selector(rightSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate rightSwipe:self];
	else if( endSwipePoint.x - beginSwipePoint.x > PIXELS_TO_COUNT_AS_SWIPE &&
			[self.delegate respondsToSelector:@selector(leftSwipe:)] )
		[(id <OzyViewDelegate>)self.delegate leftSwipe:self];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	UITouch *touch = [touches anyObject];
    NSUInteger numTaps = [touch tapCount];
	if( numTaps == 1 )
	{
		beginSwipePoint = [touch locationInView:self];
	}
	else
	{
		beginSwipePoint = CGPointZero;
	}	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	if( !CGPointEqualToPoint(beginSwipePoint, CGPointZero) )
		[self dispatchSwipe:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
}

@end
