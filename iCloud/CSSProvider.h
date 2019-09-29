//
//  CSSProvider.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-06.
//

#import <Foundation/Foundation.h>


@interface CSSProvider : NSObject

+ (NSString *) doubleColumnCSSForDarkMode:(BOOL)dark;
+ (NSString *) singleColumnCSSForDarkMode:(BOOL)dark;

+ (BOOL) customCSSExists;

+ (void) startCustomCssRetrieving;

@end
