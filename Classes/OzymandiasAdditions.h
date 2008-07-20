//
//  OzymandiasAdditions.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSString (OzymandiasExtension)
- (BOOL) containsDigit;
@end

@interface NSIndexPath (OzymandiasExtension)

+ (NSIndexPath *) indexPathWithDictionary:(NSDictionary *)d;
- (NSDictionary *) dictionaryRepresentation;

@end

@interface UITableView (OzymandiasExtension)

- (void) scrollToTopWithAnimation:(BOOL)animate;

@end

@protocol OzymandiasApplicationDelegate
@required
- (BOOL) allowRotation;
@end

