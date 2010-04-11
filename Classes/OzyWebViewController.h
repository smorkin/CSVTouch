//
//  OzyWebViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2010-04-11.
//  Copyright 2010 Ozymandias. All rights reserved.
//

#import "OzyRotatableViewController.h"

@class OzyWebView;

@interface OzyWebViewController : OzyRotatableViewController
{
	IBOutlet OzyWebView *_webView;

}

@property (nonatomic, readonly) UIWebView *webView;

@end
