//
//  SharedIPMessagingClient.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "PushManager.h"

@interface PushManager()
@property (nonatomic, strong) NSData *lastToken;
@property (nonatomic, strong) NSDictionary *lastNotification;
@end

@implementation PushManager

+ (instancetype)sharedManager {
    static PushManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)updatePushToken:(NSData *)token {
    NSLog(@"@@@@@ received updated token: %@", token);
    self.lastToken = token;
    [self updateIpMessagingClient];
}

- (void)receivedNotification:(NSDictionary *)notification {
    NSLog(@"@@@@@ received notification: %@", notification);
    self.lastNotification = notification;
    [self updateIpMessagingClient];
}

- (void)setIpMessagingClient:(TwilioIPMessagingClient *)ipMessagingClient {
    _ipMessagingClient = ipMessagingClient;
    [self updateIpMessagingClient];
}

- (void)updateIpMessagingClient {
    if (self.lastToken) {
        NSLog(@"@@@@@ registering with token: %@", self.lastToken);
        [self.ipMessagingClient registerWithToken:self.lastToken];
        self.lastToken = nil;
    }
    
    if (self.lastNotification) {
        NSLog(@"@@@@@ handling notification: %@", self.lastNotification);
        [self.ipMessagingClient handleNotification:self.lastNotification];
        self.lastNotification = nil;
    }
}

@end
