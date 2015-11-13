//
//  DemoHelpers.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DemoHelpers.h"

@implementation DemoHelpers

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block UIView *toastView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 100.0)];
        toastView.backgroundColor = [UIColor blueColor];
        toastView.layer.cornerRadius = 5.0f;
        UILabel *toastViewLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [toastView addSubview:toastViewLabel];
        [view addSubview:toastView];
        
        [toastView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [toastViewLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSMutableArray *constraints = [NSMutableArray array];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastViewLabel
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastViewLabel
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                            attribute:NSLayoutAttributeLeading
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeLeading
                                                           multiplier:1.0
                                                             constant:8.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                            attribute:NSLayoutAttributeTrailing
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeTrailing
                                                           multiplier:1.0
                                                             constant:-8.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0
                                                             constant:8.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:-8.0]];
        [toastView addConstraints:constraints];
        
        toastViewLabel.numberOfLines = 0;
        toastViewLabel.textAlignment = NSTextAlignmentCenter;
        toastViewLabel.textColor = [UIColor whiteColor];
        toastViewLabel.text = message;
        toastView.alpha = 0.0f;
        toastView.hidden = NO;
        
        constraints = [NSMutableArray array];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:toastView
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                               toItem:nil
                                                            attribute:0
                                                           multiplier:0.0
                                                             constant:100.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:0
                                                           multiplier:0.0
                                                             constant:250.0]];
        [view addConstraints:constraints];
        
        [toastView setNeedsLayout];
        
        [UIView animateWithDuration:1.25f delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             toastView.alpha = 1.0f;
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:1.25f delay:1.0f
                                                 options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:^{
                                                  toastView.alpha = 0.0f;
                                              } completion:^(BOOL finished) {
                                                  toastView.hidden = YES;
                                                  [toastView removeFromSuperview];
                                                  toastView = nil;
                                              }];
                         }];
    });
}

@end
