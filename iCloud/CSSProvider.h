//
//  CSSProvider.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-06.
//

#import <Foundation/Foundation.h>


@interface CSSProvider : NSObject

+ (NSString *) doubleColumnCSS;
+ (NSString *) singleColumnCSS;

+ (BOOL) customCSSExists;

+ (void) startCustomCssRetrieving;

@end
