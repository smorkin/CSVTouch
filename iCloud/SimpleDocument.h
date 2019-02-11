//
//  SimpleDocument.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2019-02-08.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleDocument : UIDocument

@property (copy, nonatomic) NSString* documentText;

+ (void) start;
+ (void) stop;

+ (NSString *) customCssString;

@end

NS_ASSUME_NONNULL_END
