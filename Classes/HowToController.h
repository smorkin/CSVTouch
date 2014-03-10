//
//  HowToController.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2014-03-10.
//
//

#import <UIKit/UIKit.h>

@class HowToController;

@protocol HowToControllerDelegate <NSObject>

@required
- (void) dismissHowToController;
- (NSAttributedString *) stringForController:(HowToController *)controller;
- (UIImage *) imageForController:(HowToController *)controller;
@end

@interface HowToController : UIViewController
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (assign, nonatomic) NSInteger index;
@property (retain, nonatomic) IBOutlet UITextView *howToText;

@property (nonatomic, assign) id <HowToControllerDelegate> delegate;

- (IBAction)dismissHowToView;

@end



