//
//  HowToController.m
//
//  Created by Simon Wigzell on 2014-03-10.
//
//

#import "HowToController.h"

@interface HowToController ()

@end

@implementation HowToController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView.image = [self.delegate imageForController:self];
    self.howToText.backgroundColor = [UIColor clearColor];
    self.howToText.attributedText = [self.delegate stringForController:self];
    self.imageView.image = [self.delegate imageForController:self];
    CGFloat fixedWidth = self.howToText.frame.size.width;
    CGSize newSize = [self.howToText sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = self.howToText.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    self.howToText.frame = newFrame;
//    self.howToText.dataDetectorTypes = UIDataDetectorTypeNone;
    NSLog(@"");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissHowToView
{
    [self.delegate dismissHowToController];
}

@end
