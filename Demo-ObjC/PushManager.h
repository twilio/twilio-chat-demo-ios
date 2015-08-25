//
//  SharedIPMessagingClient.h
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TwilioIPMessagingClient/TwilioIPMessagingClient.h>

@interface PushManager : NSObject

@property (nonatomic, weak) TwilioIPMessagingClient *ipMessagingClient;
           
+ (instancetype)sharedManager;

- (void)updatePushToken:(NSData *)token;

- (void)receivedNotification:(NSDictionary *)notification;

@end
