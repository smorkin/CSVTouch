//
//  FadeAnimator.m
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-27.
//

#import "FadeAnimator.h"

@implementation FadeAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:to.view];
    to.view.alpha = 0.0;

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         to.view.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                     }];
}

@end
