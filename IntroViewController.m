//
//  IntroViewController.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2014-03-15.
//
//

#import "IntroViewController.h"
#import "CSVPreferencesController.h"

#define HOW_TO_PAGES 7

@implementation IntroViewController

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

- (void) startHowToShowing:(id <IntroViewControllerDelegate>) delegate
{
    self.delegate = delegate;
    if( self.pageController == nil )
    {
        UIToolbar *bar = [[UIToolbar alloc] init];
        bar.delegate = self;
        [bar setBackgroundImage:[UIImage new]
             forToolbarPosition:UIBarPositionAny
                     barMetrics:UIBarMetricsDefault];
        [bar setShadowImage:[UIImage new]
         forToolbarPosition:UIToolbarPositionAny];
        self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        self.pageController.dataSource = self;
        self.pageController.view.backgroundColor = [UIColor colorWithRed:0.917 green:0.917 blue:0.945 alpha:1];
        [self.pageController.view addSubview:bar];
        [bar sizeToFit];
        CGRect frame = bar.frame;
        frame.origin.y += 20;
        bar.frame = frame;
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(dismissHowToController)];
        bar.items = [NSArray arrayWithObject:button];
        [self setupHowToControllers];
        
        HowToController *initialViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
        [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    self.delegate.window.rootViewController = self.pageController;
}

- (void) setupHowToControllers
{
    for( int i = 0; i < HOW_TO_PAGES; ++i)
    {
        HowToController *childViewController = [[HowToController alloc] initWithNibName:@"HowToController" bundle:nil];
        childViewController.index = i;
        childViewController.delegate = self;
        CGRect rect = self.delegate.window.rootViewController.view.frame;
        childViewController.view.frame = rect;
        [_howToControllers addObject:childViewController];
    }
}

- (HowToController *)viewControllerAtIndex:(NSUInteger)index {
    return [_howToControllers objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [(HowToController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [(HowToController *)viewController index];
    
    
    index++;
    
    if (index == HOW_TO_PAGES) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return HOW_TO_PAGES;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

- (void)dismissHowToController
{
    [self.delegate dismissHowToController:self];
}

- (NSString *)titleForHowTo:(NSInteger)index
{
    switch(index)
    {
        case 0:
            return NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
        case 1:
            return @"Dropbox, Google Drive etc";
        case 2:
            return @"Mail, messages etc";
        case 3:
            return @"iTunes";
        case 4:
            return @"Direct internet access";
        case 5:
            return @"Advanced";
        case 6:
            return @"Troubleshooting";
        default:
            return @"";
    }
}

- (NSString *)textForHowTo:(NSInteger)index
{
    NSString *appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    switch(index)
    {
        case 0:
        {
            NSMutableString *s = [NSMutableString stringWithString:@"Welcome! To get started, you first need to get your CSV file(s) into the app. There are multiple ways of doing this, presented on the following pages."];
            if( [CSVPreferencesController restrictedDataVersionRunning])
            {
                [s appendString:@"\n\nNOTE: This free version is restricted to 1 file and only shows the 150 first items."];
            }
            return s;
        }
        case 1:
            return [NSString stringWithFormat:@"By adding your file to any cloud drive which has an app for iOS, you can simply go to that app and select to open the CSV file in %@.", appName];
        case 2:
            return @"Similarly, you can select to open a CSV file which has been sent to you by mail or messaging apps which allow you to send files.";
        case 3:
            return [NSString stringWithFormat:@"If you connect your device to iTunes, you can add CSV files directly in iTunes in the same way you add files to any app: Select the device, select the Apps tab, and scroll down until you see %@. Then you add the files there.", appName];
        case 4:
            return [NSString stringWithFormat:@"If your file is accessibly directly from internet, you can select the \"+\" button in %@ and then input the address to your file. See http://www.ozymandias.se for more details about how to use this feature.", appName];
        case 5:
            return [NSString stringWithFormat:@"Finally, there are some more unusual ways of getting your files into %@. See the full documentation at http://www.ozymandias.se.", appName];
        case 6:
            return @"If you are having problems, please check the full documentation at http://www.ozymandias.se; if that still doesn't help, you can always mail me (email address available in the AppStore) :-)";
        default:
            return @"";
    }
}

- (NSAttributedString *) stringForController:(HowToController *)controller
{
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
    NSString *title = [self titleForHowTo:controller.index];
    NSString *text = [self textForHowTo:controller.index];
    [s.mutableString appendString:title];
    [s.mutableString appendString:@"\n\n"];
    [s.mutableString appendString:text];
    
    //add alignments for title
    NSMutableParagraphStyle *centeredParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [centeredParagraphStyle setAlignment:NSTextAlignmentCenter];
    [s addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:NSMakeRange(0, title.length)];
    //add alignment for text
    NSMutableParagraphStyle *normalParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [normalParagraphStyle setAlignment:NSTextAlignmentNatural];
    [s addAttribute:NSParagraphStyleAttributeName value:normalParagraphStyle range:NSMakeRange(title.length, text.length+2)];
    
    //add larger font for title
    UIFont *font = [controller.howToText.font fontWithSize:20];
    [s addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, title.length)];
    
    return s;
}

- (UIImage *) imageForController:(HowToController *)controller
{
    switch(controller.index)
    {
        case 1:
            return [UIImage imageNamed:@"file_via_app.png"];
        case 2:
            return [UIImage imageNamed:@"file_via_mail.png"];
        case 3:
            return [UIImage imageNamed:@"file_via_itunes.png"];
        case 4:
            return [UIImage imageNamed:@"file_via_internet.png"];
        default:
            return nil;
    }
}

- (id)init
{
	if (self = [super init])
	{
        _howToControllers = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
    _howToControllers = nil;
}

@end
