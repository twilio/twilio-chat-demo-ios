//
//  DemoHelpers.h
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioIPMessagingClient/TwilioIPMessagingClient.h>
#import <TwilioIPMessagingClient/TWMUserInfo.h>

@interface DemoHelpers : NSObject

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view;

+ (NSString *)displayNameForMember:(TWMMember *)member;

+ (NSString *)messageDisplayForDateString:(NSString *)dateString;

+ (UIImage *)avatarForUserInfo:(TWMUserInfo *)userInfo
                          size:(NSUInteger)size
                 scalingFactor:(CGFloat)scale;

@end
