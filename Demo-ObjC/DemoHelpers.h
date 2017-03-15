//
//  DemoHelpers.h
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioChatClient/TwilioChatClient.h>
#import <TwilioChatClient/TCHUserInfo.h>

@interface DemoHelpers : NSObject

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view;

+ (NSString *)displayNameForMember:(TCHMember *)member;

+ (NSString *)messageDisplayForDate:(NSDate *)date;

+ (UIImage *)avatarForUserInfo:(TCHUserInfo *)userInfo
                          size:(NSUInteger)size
                 scalingFactor:(CGFloat)scale;

+ (UIImage *)avatarForAuthor:(NSString *)author
                        size:(NSUInteger)size
               scalingFactor:(CGFloat)scale;

+ (NSMutableDictionary *)deepMutableCopyOfDictionary:(NSDictionary *)dictionary;

+ (void)reactionIncrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity;

+ (void)reactionDecrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity;

@end
