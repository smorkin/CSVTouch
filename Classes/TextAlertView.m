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

//
///*
// *	Determine the y-coordinate of the alert view's title
// */
- (CGFloat) textFieldYOffset {
	for( UIView *view in self.subviews ){
		if([view isKindOfClass:[UILabel class]] &&
		   [[(UILabel *)view text] isEqual:[self title]])
		{
			CGRect viewFrame = [view frame];
			return viewFrame.origin.y + viewFrame.size.height;
		}
	}
	return 0;
}
/*
 *	Initialize view with maximum of two buttons
 */
- (id)initWithTitle:(NSString *)title
		   delegate:(id)delegate 
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	self = [super initWithTitle:title
						message:@"\n\n" 
					   delegate:delegate
			  cancelButtonTitle:cancelButtonTitle
			  otherButtonTitles:otherButtonTitles, nil];
	if (self)
	{
		
		
		
//		UITextField *textField;
//		UITextField *textField2;
//		
//		UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Username and password" 
//														 message:@"\n\n\n" // IMPORTANT
//														delegate:nil 
//											   cancelButtonTitle:@"Cancel" 
//											   otherButtonTitles:@"Enter", nil];
//		
//		textField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 50.0, 260.0, 25.0)]; 
//		[textField setBackgroundColor:[UIColor whiteColor]];
//		[textField setPlaceholder:@"username"];
//		[prompt addSubview:textField];
//		
//		textField2 = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 85.0, 260.0, 25.0)]; 
//		[textField2 setBackgroundColor:[UIColor whiteColor]];
//		[textField2 setPlaceholder:@"password"];
//		[textField2 setSecureTextEntry:YES];
//		[prompt addSubview:textField2];
//		
//		// set place
//		[prompt setTransform:CGAffineTransformMakeTranslation(0.0, 110.0)];
//		[prompt show];
//		[prompt release];
//		
//		// set cursor and show keyboard
//		[textField becomeFirstResponder];
		
		
		
		
		
		
		
		
		
		
		
		
		// Create and add UITextField to UIAlertView
		UITextField *myTextField = [[[UITextField alloc] initWithFrame:CGRectZero] retain];
		myTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		myTextField.alpha = 0.75;
		myTextField.borderStyle = UITextBorderStyleRoundedRect;
		myTextField.delegate = delegate;
		myTextField.secureTextEntry = YES;
		[self setTextField:myTextField];		
	}
	return self;
}

/*
 *	Show alert view and make keyboard visible
 */
- (void) show {
	[super show];
	[[self textField] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.6];
//	[[self textField] becomeFirstResponder];
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
		
//		viewFrame = [[self buttonsView] frame];
//		viewFrame.origin.y += kUITextFieldHeight;
//		[[self buttonsView] setFrame:viewFrame];
		
		[self addSubview:self.textField];
		viewFrame = CGRectMake(kUITextFieldXPadding, 
							   [self textFieldYOffset] + kUITextFieldYPadding, 
							   self.frame.size.width - 4.0*kUITextFieldXPadding, 
							   kUITextFieldHeight);
		[self.textField setFrame:viewFrame];
		
		// size UIAlertView frame by height of UITextField
//		frame.size.height += kUITextFieldHeight + 2.0;
//		[self setFrame:frame];
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
