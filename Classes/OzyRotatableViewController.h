//
//  OzyRotatableViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 17/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OzyRotatableViewController : UIViewController {
	IBOutlet UIView *_contentView;
}

@property (nonatomic, weak) id viewDelegate;
@property (nonatomic, strong, readonly) UIView *contentView;

@end
