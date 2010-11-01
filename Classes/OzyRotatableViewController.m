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
@interface OzyRotatableViewController (ADBannerViewDelegate) <ADBannerViewDelegate>
@end
#endif


@implementation OzyRotatableViewController

@synthesize viewDelegate = _viewDelegate;
@synthesize contentView = _contentView;
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@synthesize bannerView = _bannerView;
@synthesize bannerIsVisible = _bannerIsVisible;
#endif


- (void) setupBannerView
{
	// Ads
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
#ifndef __IPHONE_4_2
	NSString *contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ?
	ADBannerContentSizeIdentifier320x50 : ADBannerContentSizeIdentifier480x32;
#else
	NSString *contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ?
	ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifierLandscape;
#endif
	
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0, CGRectGetMaxY(self.view.bounds));
	
	ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    bannerView.delegate = self;
    // Set the autoresizing mask so that the banner is pinned to the bottom
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
	
	// On iOS 4.2, default is both portrait and landscape
#ifndef __IPHONE_4_2
	self.bannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects: ADBannerContentSizeIdentifier320x50,
													  ADBannerContentSizeIdentifier480x32,
													  nil];
#endif	
	
	[self.view addSubview:bannerView];
    self.bannerView = bannerView;
    [bannerView release];	
	
#endif	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if( [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(allowRotation)] )
		return [(id <OzymandiasApplicationDelegate>)[[UIApplication sharedApplication] delegate] allowRotation];
	else
		return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.viewDelegate viewDidAppear:self.view controller:self];
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	if( self.bannerView == nil )
		[self setupBannerView];
#endif
	
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.viewDelegate viewDidDisappear:self.view controller:self];
	[super viewDidDisappear:animated];
}

- (void) dealloc
{
#if defined(__IPHONE_4_0) && defined(CSV_LITE)
	self.bannerView.delegate = nil;
#endif	
	self.viewDelegate = nil;
	[super dealloc];
}

@end


#if defined(__IPHONE_4_0) && defined(CSV_LITE)
@implementation OzyRotatableViewController (AdBannerViewDelegate)

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
//								duration:(NSTimeInterval)duration
//{
//    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
//#ifndef __IPHONE_4_2
//        self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
//#else
//	self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
//#endif
//    else
//#ifndef __IPHONE_4_2
//        self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
//#else
//	self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//#endif
//}

-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2 : 0.0;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
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
	self.bannerView.currentContentSizeIdentifier = contentSizeIdentifier;
	bannerHeight = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSizeIdentifier].height;
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    // This layout is for an ad at the bottom of the view.
    if(self.bannerView.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
    }
    else
    {
		bannerOrigin.y += bannerHeight;
    }
    
	
    // And finally animate the changes, running layout for the content view if required.
    [UIView animateWithDuration:animationDuration
                     animations:^{
						 self.contentView.frame = contentFrame;
						 [self.contentView layoutIfNeeded];
						 self.bannerView.frame = CGRectMake(bannerOrigin.x,
															bannerOrigin.y,
															self.bannerView.frame.size.width,
															self.bannerView.frame.size.height);
					 }
	 ];
	NSLog(@"Done");
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if (!self.bannerIsVisible)
    {
		[self layoutForCurrentOrientation:YES];
        self.bannerIsVisible = YES;
    }
}	

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if (self.bannerIsVisible)
    {
		[self layoutForCurrentOrientation:YES];
        self.bannerIsVisible = NO;
    }	
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	// We have no restrictions about when we can leave app or not, and nothing to stop
	return YES;
}	

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	// Nothing for us to do here
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										duration:(NSTimeInterval)duration
{
    [self layoutForCurrentOrientation:YES];
}


@end
#endif
