//
//  OzyRotatableTabBarController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OzyRotatableTabBarController : UITabBarController {
	id _viewDelegate;
}

@property (nonatomic, assign) id viewDelegate;

@end
