//
//  OzymandiasAdditions.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSString (OzymandiasExtension)
+ (NSString *) httpStatusDescription:(NSInteger)status;
- (BOOL) containsDigit;
- (BOOL) hasSubstring:(NSString *)s;
- (BOOL) hasImageExtension;
- (BOOL) hasMovieExtension;
- (BOOL) containsURL;
- (BOOL) containsImageURL;
- (BOOL) containsLocalImageURL;
- (BOOL) containsLocalMovieURL;
- (BOOL) containsMailAddress;
- (NSComparisonResult) numericSensitiveCompare:(NSString *)s;
- (NSData *) ozyHash;
@end

@interface NSIndexPath (OzymandiasExtension)

+ (NSIndexPath *) indexPathWithDictionary:(NSDictionary *)d;
- (NSDictionary *) dictionaryRepresentation;

@end

@interface UIAlertController (OzymandiasExtension)
+ (UIAlertController *) alertControllerWithTitle:(NSString *)title
                                         message:(NSString *)message
                                   okButtonTitle:(NSString *)okTitle
                                       okHandler:(void (^)(UIAlertAction *action))okHandler;

+ (UIAlertController *) alertControllerWithTitle:(NSString *)title
                                         message:(NSString *)message
                                   okButtonTitle:(NSString *)okTitle
                                       okHandler:(void (^)(UIAlertAction *action))okHandler
                               cancelButtonTitle:(NSString *)cancelTitle
                                       cancelHandler:(void (^)(UIAlertAction *action))cancelHandler;

@end

@interface UITableView (OzymandiasExtension)

- (void) scrollToTopWithAnimation:(BOOL)animate;

@end

@protocol OzymandiasApplicationDelegate
@required
@end

@interface OzyTableView : UITableView
{
	CGPoint beginSwipePoint;
}
@end

@interface OzyWebView : UIWebView
{
	CGPoint beginSwipePoint;
}
@end

@interface OzyTextView : UITextView
{
	CGPoint beginSwipePoint;
}
@end

@protocol OzyViewDelegate
@optional
- (void) rightSwipe:(UIView *) swipeView;
- (void) leftSwipe:(UIView *) swipeView;
@end
