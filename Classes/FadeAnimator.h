//
//  FadeAnimator.h
//  CSV Touch
//
//  Created by Simon Wigzell on 2017-12-27.
//

#import <Foundation/Foundation.h>

@interface FadeAnimator : NSObject <UIViewControllerAnimatedTransitioning>

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext;

// This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;

@end
