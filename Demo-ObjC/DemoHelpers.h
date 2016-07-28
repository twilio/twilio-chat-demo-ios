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

+ (NSString *)messageDisplayForDate:(NSDate *)date;

+ (UIImage *)avatarForUserInfo:(TWMUserInfo *)userInfo
                          size:(NSUInteger)size
                 scalingFactor:(CGFloat)scale;

+ (UIImage *)avatarForAuthor:(NSString *)author
                        size:(NSUInteger)size
               scalingFactor:(CGFloat)scale;

+ (NSMutableDictionary *)deepMutableCopyOfDictionary:(NSDictionary *)dictionary;

+ (void)reactionIncrement:(NSString *)emojiString message:(TWMMessage *)message user:(NSString *)identity;

+ (void)reactionDecrement:(NSString *)emojiString message:(TWMMessage *)message user:(NSString *)identity;

@end
