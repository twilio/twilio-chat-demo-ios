//
//  DemoHelpers.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>

#import "DemoHelpers.h"

@interface DemoHelpers()
@property (nonatomic, strong) NSMutableDictionary *imageCache;
@end

@implementation DemoHelpers

- (instancetype)init {
    if ((self = [super init]) != nil) {
        self.imageCache = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static DemoHelpers *sharedHelpers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelpers = [[self alloc] init];
    });
    return sharedHelpers;
}

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view {
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
}

+ (NSString *)displayNameForMember:(TWMMember *)member {
    NSString *displayName = nil;
    NSString *friendlyName = [[member userInfo] friendlyName];
    if (![friendlyName isEqualToString:@""]) {
        displayName = friendlyName;
    } else {
        displayName = [[member userInfo] identity];
    }
    return displayName;
}

+ (UIImage *)avatarForUserInfo:(TWMUserInfo *)userInfo
                          size:(NSUInteger)size
                 scalingFactor:(CGFloat)scale {
    NSString *email = userInfo.attributes[@"email"];
    NSString *identity = userInfo.identity;
    
    NSMutableDictionary *imageCache = [[self sharedInstance] imageCache];
    NSString *cacheKey = [NSString stringWithFormat:@"%@:%@", email, identity];
    UIImage *avatarImage = imageCache[cacheKey];
    if (!avatarImage) {
        if (email && ![email isEqualToString:@""]) {
            avatarImage = [self gravatarForEmail:email
                                            size:size
                                   scalingFactor:scale];
            imageCache[cacheKey] = avatarImage;
        }
        if (!avatarImage) {
            avatarImage = [self randomAvatarForIdentity:identity
                                                   size:size
                                          scalingFactor:scale];
            imageCache[cacheKey] = avatarImage;
        }
    }
    return avatarImage;
}

#pragma mark - Internal helper methods

+ (NSString *)md5ForString:(NSString *)input {
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    [self md5ForString:input output:md5];
    NSMutableString *ret = [NSMutableString string];
    for (int ndx=0; ndx < CC_MD5_DIGEST_LENGTH; ndx++) {
        [ret appendFormat:@"%02x", md5[ndx]];
    }
    return ret;
}

+ (void)md5ForString:(NSString *)input output:(unsigned char *)output {
    const char *inputCString = [input UTF8String];
    CC_MD5(inputCString, (CC_LONG)strlen(inputCString), output);
}

+ (UIImage *)gravatarForEmail:(NSString *)email
                         size:(NSUInteger)size
                scalingFactor:(CGFloat)scale {
    NSString *emailHash = [self md5ForString:email];
    NSString *avatarURLString = [NSString stringWithFormat:@"https://www.gravatar.com/avatar/%@?d=404&s=%ld", emailHash, (NSUInteger)(size*scale)];
    NSURL *avatarURL = [NSURL URLWithString:avatarURLString];
    NSData *data = [NSData dataWithContentsOfURL:avatarURL];
    UIImage *avatarImage = [UIImage imageWithData:data scale:scale];

    CGSize imageSize = avatarImage.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, avatarImage.scale);
    CGRect bounds = (CGRect){CGPointZero, imageSize};
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:imageSize.height / 2.0f] addClip];
    [avatarImage drawInRect:bounds];
    avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return avatarImage;
}

+ (UIImage *)randomAvatarForIdentity:(NSString *)identity
                                size:(NSUInteger)size
                       scalingFactor:(CGFloat)scale {
    UIImage *avatarImage = nil;
    
    CGRect bounds = (CGRect){CGPointZero, CGSizeMake(size, size)};
    UIGraphicsBeginImageContext(bounds.size);
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:bounds.size.height / 2.0f] addClip];
    
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    [self md5ForString:identity output:md5];
    UIColor *color = [UIColor colorWithRed:(md5[0] / 255.0)
                                     green:(md5[1] / 255.0)
                                      blue:(md5[2] / 255.0)
                                     alpha:1.0f];
    
    UIImage *twilioLogo = [UIImage imageNamed:@"user-44px"];
    twilioLogo = [twilioLogo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGSize imageSize = twilioLogo.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, twilioLogo.scale);
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:imageSize.height / 2.0f] addClip];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, bounds);

    [[UIColor colorWithWhite:0.0f
                       alpha:0.5f] set];
    [twilioLogo drawInRect:bounds];
    
    avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return avatarImage;
}

@end
