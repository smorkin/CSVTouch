//
//  HelpPagesViewController.m
//  Heartfeed
//
//  Created by Simon Wigzell on 2016-01-25.
//  Copyright © 2016 Ozymandias. All rights reserved.
//

#import "HelpPagesViewController.h"
#import "HowToController.h"

@interface HelpPagesViewController ()
@property (strong, nonatomic) id <HelpPagesViewDelegate, NSObject> helpPageDelegate;
@end

@implementation HelpPagesViewController

- (instancetype) initWithDelegate:(id <HelpPagesViewDelegate, NSObject>)delegate
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:nil];
    self.helpPageDelegate = delegate;
    [self setupHelpPages];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.dataSource = self;
    self.view.backgroundColor = [UIColor colorWithRed:0.917 green:0.917 blue:0.945 alpha:1];
    if( [self.helpPages count] > 0 )
    {
        [self setViewControllers:[NSArray arrayWithObject:[self.helpPages objectAtIndex:0]]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
    }
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    return self;
}

- (void) setupHelpPages
{
    self.helpPages = [NSMutableArray array];
    for( int i = 0; i < [self.helpPageDelegate numberOfPages]; ++i)
    {
        HowToController *controller = [[HowToController alloc] initWithNibName:@"HowToController" bundle:nil];
        controller.index = i;
        controller.delegate = self;
        [self.helpPages addObject:controller];
    }

}

- (HowToController *) helpPageAtIndex:(NSInteger)index
{
    if( index < 0 || index >= self.helpPages.count)
    {
        return nil;
    }
    
    return [self.helpPages objectAtIndex:index];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    return [self helpPageAtIndex:[(HowToController *)viewController index]-1];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    return [self helpPageAtIndex:[(HowToController *)viewController index]+1];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.helpPageDelegate numberOfPages];
}
- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void) dismissHowToController
{
}

- (UIImage *) imageForController:(HowToController *)controller
{
    return [self.helpPageDelegate imageForHelpPage:controller.index];
}

- (NSAttributedString *) stringForController:(HowToController *)controller
{
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
    NSString *title = [self.helpPageDelegate titleForHelpPage:controller.index];
    NSString *text = [self.helpPageDelegate textForHelpPage:controller.index];
    NSString *joinString = @"\n\n";
    [s.mutableString appendString:title];
    [s.mutableString appendString:joinString];
    [s.mutableString appendString:text];
    
    //add alignments for title
    NSMutableParagraphStyle *centeredParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [centeredParagraphStyle setAlignment:NSTextAlignmentCenter];
    [s addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:NSMakeRange(0, title.length)];
    //add alignment for text
    NSMutableParagraphStyle *normalParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [normalParagraphStyle setAlignment:NSTextAlignmentNatural];
    [s addAttribute:NSParagraphStyleAttributeName value:normalParagraphStyle range:NSMakeRange(title.length + joinString.length
                                                                                               ,text.length)];
    
    //add larger font for title
    CGFloat titleSize;
    CGFloat textSize;
    if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad )
    {
        titleSize = 22;
        textSize = 18;
    }
    else
    {
        titleSize = 16;
        textSize = 11;
    }
    UIFont *titleFont = [controller.howToText.font fontWithSize:titleSize];
    [s addAttribute:NSFontAttributeName value:titleFont range:NSMakeRange(0, title.length)];
    UIFont *textFont = [controller.howToText.font fontWithSize:textSize];
    [s addAttribute:NSFontAttributeName value:textFont range:NSMakeRange(title.length + joinString.length, text.length)];
    
    return s;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    if( !parent && self.helpPageDelegate && [self.helpPageDelegate respondsToSelector:@selector(helpPagesShowCompleted:)])
    {
        [self.helpPageDelegate helpPagesShowCompleted:self];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
