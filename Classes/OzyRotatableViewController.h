//
//  OzyRotatableViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
#import <iAd/iAd.h>
#endif

@interface OzyRotatableViewController : UIViewController {
	id _viewDelegate;
	IBOutlet UIView *_contentView;

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	// Ad support
	ADBannerView *_bannerView;
	BOOL _bannerIsVisible;
#endif
	
}

@property (nonatomic, assign) id viewDelegate;
@property (nonatomic, readonly) UIView *contentView;
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@property (nonatomic, retain) ADBannerView *bannerView;
@property (nonatomic, assign) BOOL bannerIsVisible;
#endif

@end
