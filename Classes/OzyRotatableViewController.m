//
//  OzyRotatableViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyRotatableViewController.h"
#import "OzymandiasAdditions.h"
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
#import <iAd/iAd.h>
#endif



@implementation OzyRotatableViewController

@synthesize viewDelegate = _viewDelegate;
@synthesize contentView = _contentView;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if( [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(allowRotation)] )
		return [(id <OzymandiasApplicationDelegate>)[[UIApplication sharedApplication] delegate] allowRotation];
	else
		return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.viewDelegate viewDidAppear:self.view controller:self];	
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.viewDelegate viewDidDisappear:self.view controller:self];
	[super viewDidDisappear:animated];
}

- (void) dealloc
{
	self.viewDelegate = nil;
	[super dealloc];
}

@end

#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@interface OzyRotatableViewController (ShowingAdBanners) <OzymandiasShowingAdBanners>
@end

@implementation OzyRotatableViewController (ShowingAdBanners) 

-(void)layoutForCurrentOrientation:(ADBannerView *)bannerView animated:(BOOL)animated
{
	if( ![[self.contentView subviews] containsObject:bannerView] )
		[self.view addSubview:bannerView];
	
    CGFloat animationDuration = animated ? 0.2 : 0.0;
    CGRect contentFrame = self.view.bounds;
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0;
	NSString *contentSizeIdentifier;
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
#ifndef __IPHONE_4_2
		contentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
#else
		contentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
#endif
	}
    else
	{
#ifndef __IPHONE_4_2
 		contentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
#else
 		contentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
#endif
	}
	bannerView.currentContentSizeIdentifier = contentSizeIdentifier;
	bannerHeight = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSizeIdentifier].height;
	
    if(bannerView.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    }
    else
    {
		bannerOrigin.y += bannerHeight;
    }
    
	
    [UIView animateWithDuration:animationDuration
                     animations:^{
						 self.contentView.frame = contentFrame;
						 [self.contentView layoutIfNeeded];
						 bannerView.frame = CGRectMake(bannerOrigin.x,
													   bannerOrigin.y,
													   bannerView.frame.size.width,
													   bannerView.frame.size.height);
					 }
	 ];
}
@end
#endif 
