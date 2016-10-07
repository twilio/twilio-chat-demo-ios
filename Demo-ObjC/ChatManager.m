//
//  ChatManager.m
//  Twilio Chat Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatManager.h"

@interface ChatManager()
@property (nonatomic, strong) TwilioChatClient *client;

@property (nonatomic, strong) NSData *lastToken;
@property (nonatomic, strong) NSDictionary *lastNotification;
@end

@implementation ChatManager

+ (instancetype)sharedManager {
    static ChatManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)presentRootViewController {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[ChatManager sharedManager] hasIdentity]) {
        if (!self.client) {
            [[ChatManager sharedManager] loginWithStoredIdentity];
        }
        appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    } else {
        appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"login"];
    }
}

- (BOOL)hasIdentity {
    return ([self storedIdentity] && [self storedIdentity].length > 0);
}

- (BOOL)loginWithStoredIdentity {
    if ([self hasIdentity]) {
        return [self loginWithIdentity:[self storedIdentity]];
    } else {
        return NO;
    }
}

- (BOOL)loginWithIdentity:(NSString *)identity {
    if (self.client) {
        [self logout];
    }
    
    [self storeIdentity:identity];
    
    NSString *token = [self tokenForIdentity:identity];
    TwilioChatClientProperties *properties = [[TwilioChatClientProperties alloc] init];
    properties.initialMessageCount = 10;
    self.client = [TwilioChatClient chatClientWithToken:token
                                             properties:properties
                                               delegate:nil];

    return YES;
}

- (void)logout {
    [self storeIdentity:nil];
    [self.client shutdown];
    self.client = nil;
}

- (void)updatePushToken:(NSData *)token {
    self.lastToken = token;
    [self updateChatClient];
}

- (void)receivedNotification:(NSDictionary *)notification {
    self.lastNotification = notification;
    [self updateChatClient];
}

- (NSString *)identity {
    return [[[self client] userInfo] identity];
}

#pragma mark Push functionality

- (void)updateChatClient {
    if (self.lastToken) {
        [self.client registerWithToken:self.lastToken];
        self.lastToken = nil;
    }
    
    if (self.lastNotification) {
        [self.client handleNotification:self.lastNotification];
        self.lastNotification = nil;
    }
}

#pragma mark Internal helpers

- (NSString *)tokenForIdentity:(NSString *)identity {
#error - Use the capability string generated in the Twilio SDK portal to populate the token variable and delete this line to build the Demo.
    return nil;
}

- (void)storeIdentity:(NSString *)identity {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:identity forKey:@"identity"];
}

- (NSString *)storedIdentity {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"identity"];
}

@end
