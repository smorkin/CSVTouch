//
//  HowToController.m
//  CSV Touch
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

    // Do any additional setup after loading the view from its nib.
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

- (void)dealloc {
    [_howToText release];
    [_imageView release];
    [super dealloc];
}
@end
