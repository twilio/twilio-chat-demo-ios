//
//  ChatManager.h
//  Twilio Chat Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioChatClient/TwilioChatClient.h>

@interface ChatManager : NSObject

@property (nonatomic, strong, readonly) TwilioChatClient *client;

+ (instancetype)sharedManager;

- (void)presentRootViewController;
- (BOOL)hasIdentity;
- (BOOL)loginWithStoredIdentity;
- (BOOL)loginWithIdentity:(NSString *)identity;
- (void)logout;

- (void)updatePushToken:(NSData *)token;
- (void)receivedNotification:(NSDictionary *)notification;

- (NSString *)identity;

@end
