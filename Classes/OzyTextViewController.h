//
//  OzyTextViewController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 18/06/2008.
//  Copyright 2008 Ozymandias. All rights reserved.
//

#import "OzyRotatableViewController.h"


@interface OzyTextViewController : OzyRotatableViewController
{
	IBOutlet UITextView *_textView;
}

@property (nonatomic, readonly) UITextView *textView;

@end
