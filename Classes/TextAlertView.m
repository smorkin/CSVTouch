/*
 *	Text Alert View
 *
 *  File: TextAlertView.m
 *	Abstract: UIAlertView extension with UITextField (Implementation).
 *
 */

#import "TextAlertView.h"

@implementation TextAlertView

@synthesize textField;


/*
 *	Determine maximum y-coordinate of UILabel objects. This method assumes that only
 *	following objects are contained in subview list:
 *	- UILabel
 *	- UITextField
 *	- UIThreePartButton (Private Class)
 */
- (CGFloat) maxLabelYCoordinate {
	// Determine maximum y-coordinate of labels
	CGFloat maxY = 0;
	for( UIView *view in self.subviews ){
		if([view isKindOfClass:[UILabel class]]) {
			CGRect viewFrame = [view frame];
			CGFloat lowerY = viewFrame.origin.y + viewFrame.size.height;
			if(lowerY > maxY)
				maxY = lowerY;
		}
	}
	return maxY;
}
/*
 *	Initialize view with maximum of two buttons
 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate 
  cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
	self = [super initWithTitle:title
						message:message 
					   delegate:delegate
			  cancelButtonTitle:cancelButtonTitle
			  otherButtonTitles:otherButtonTitles, nil];
	if (self)
	{
		// Create and add UITextField to UIAlertView
		UITextField *myTextField = [[[UITextField alloc] initWithFrame:CGRectZero] retain];
		myTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		myTextField.alpha = 0.75;
		myTextField.borderStyle = UITextBorderStyleRoundedRect;
		myTextField.delegate = delegate;
		myTextField.secureTextEntry = YES;
		[self setTextField:myTextField];
		
		// insert UITextField before first button
//		for( UIView *view in self.subviews ){
//			if(![view isKindOfClass:[UILabel class]])
//			{
//				[self insertSubview:myTextField aboveSubview:view];
//				break;
//			}
//		}
		
		// ensure that layout for views is done once
		layoutDone = NO;
		
		// add a transform to move the UIAlertView above the keyboard
//		CGAffineTransform myTransform = CGAffineTransformMakeTranslation(0.0, kUIAlertOffset);
//		[self setTransform:myTransform];
	}
	return self;
}

/*
 *	Show alert view and make keyboard visible
 */
- (void) show {
	[super show];
	[[self textField] becomeFirstResponder];
}

- (UIView *) buttonsView
{
	return [[self subviews] lastObject]; // TODO: Kan bara anropas innan layoutDone=YES
}

/*
 *	Override layoutSubviews to correctly handle the UITextField
 */
- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect frame = [self frame];
	CGFloat alertWidth = frame.size.width;
	
	// Perform layout of subviews just once
	if(!layoutDone) {
		CGRect viewFrame;
		
		viewFrame = [[self buttonsView] frame];
		viewFrame.origin.y += kUITextFieldHeight;
		[[self buttonsView] setFrame:viewFrame];
		
		[self addSubview:self.textField];
		viewFrame = CGRectMake(kUITextFieldXPadding, 
							   [self maxLabelYCoordinate] + kUITextFieldYPadding, 
							   self.frame.size.width - 4.0*kUITextFieldXPadding, 
							   kUITextFieldHeight);
		[self.textField setFrame:viewFrame];
		
		
		// Insert UITextField below labels and move other fields down accordingly
//		for(UIView *view in self.subviews){
//		    if([view isKindOfClass:[UITextField class]]){
//				CGRect viewFrame = CGRectMake(
//											  kUITextFieldXPadding, 
//											  labelMaxY + kUITextFieldYPadding, 
//											  alertWidth - 4.0*kUITextFieldXPadding, 
//											  kUITextFieldHeight);
//				[view setFrame:viewFrame];
//		    } else if(![view isKindOfClass:[UILabel class]]) { // knappar
//				CGRect viewFrame = [view frame];
//				viewFrame.origin.y += kUITextFieldHeight;
//				[view setFrame:viewFrame];
//			}
//		}
		
		// size UIAlertView frame by height of UITextField
		frame.size.height += kUITextFieldHeight + 2.0;
		[self setFrame:frame];
		layoutDone = YES;
	}
	else
	{
		// reduce the x placement and width of the UITextField based on UIAlertView width
		for(UIView *view in self.subviews){
		    if([view isKindOfClass:[UITextField class]]){
				CGRect viewFrame = [view frame];
				viewFrame.origin.x = kUITextFieldXPadding;
				viewFrame.size.width = alertWidth - 4.0*kUITextFieldXPadding;
				[view setFrame:viewFrame];
		    }
		}
	}
}

@end
