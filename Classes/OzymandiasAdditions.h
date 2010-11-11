//
//  OzymandiasAdditions.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/07/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
#import <iAd/iAd.h>
#endif


@interface NSString (OzymandiasExtension)
+ (NSString *) httpStatusDescription:(NSInteger)status;
- (BOOL) containsDigit;
- (BOOL) hasSubstring:(NSString *)s;
- (BOOL) containsURL;
- (BOOL) containsImageURL;
- (BOOL) containsMailAddress;
- (NSComparisonResult) numericSensitiveCompare:(NSString *)s;
- (NSData *) ozyHash;
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

@protocol OzymandiasViewControllerViewDelegate
@required
- (void) viewDidAppear:(UIView *)view controller:(UIViewController *)controller;
- (void) viewDidDisappear:(UIView *)view controller:(UIViewController *)controller;
@end

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@protocol OzymandiasShowingAdBanners
@required
-(void)layoutForCurrentOrientation:(ADBannerView *)bannerView animated:(BOOL)animated;
@end
#endif

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
