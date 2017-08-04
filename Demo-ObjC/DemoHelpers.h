//
//  DemoHelpers.h
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioChatClient/TwilioChatClient.h>
#import <TwilioChatClient/TCHUser.h>

@interface DemoHelpers : NSObject

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view;

+ (NSString *)displayNameForUser:(TCHUser *)user;

+ (NSString *)messageDisplayForDate:(NSDate *)date;

+ (UIImage *)avatarForUser:(TCHUser *)user
                      size:(NSUInteger)size
             scalingFactor:(CGFloat)scale;

+ (UIImage *)avatarForAuthor:(NSString *)author
                        size:(NSUInteger)size
               scalingFactor:(CGFloat)scale;

+ (NSMutableDictionary *)deepMutableCopyOfDictionary:(NSDictionary *)dictionary;

+ (void)reactionIncrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity;

+ (void)reactionDecrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity;

+ (UIImage *)cachedImageForMessage:(TCHMessage *)message;

+ (void)loadImageForMessage:(TCHMessage *)message
             progressUpdate:(void(^)(CGFloat progress))progressUpdate
                 completion:(void(^)(UIImage *image))completion;

+ (UIImage *)image:(UIImage *)image scaledToWith:(CGFloat)width;

@end
