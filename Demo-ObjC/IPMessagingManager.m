//
//  IPMessagingManager.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "IPMessagingManager.h"

@interface IPMessagingManager() <TwilioAccessManagerDelegate>
@property (nonatomic, strong) TwilioIPMessagingClient *client;
@property (nonatomic, strong) TwilioAccessManager *accessManager;

@property (nonatomic, strong) NSData *lastToken;
@property (nonatomic, strong) NSDictionary *lastNotification;
@end

@implementation IPMessagingManager

+ (instancetype)sharedManager {
    static IPMessagingManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)presentRootViewController {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if ([[IPMessagingManager sharedManager] hasIdentity]) {
        [[IPMessagingManager sharedManager] loginWithStoredIdentity];
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
    self.accessManager = [TwilioAccessManager accessManagerWithToken:token delegate:self];
    TwilioIPMessagingClientProperties *properties = [[TwilioIPMessagingClientProperties alloc] init];
    properties.initialMessageCount = 10;
    self.client = [TwilioIPMessagingClient ipMessagingClientWithAccessManager:self.accessManager
                                                                   properties:properties
                                                                     delegate:nil];
    
    return YES;
}

- (void)accessManagerTokenExpired:(TwilioAccessManager *)accessManager {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *newToken = [self tokenForIdentity:accessManager.identity];
        [accessManager updateToken:newToken];
    });
}

- (void)accessManager:(TwilioAccessManager *)accessManager error:(NSError *)error {
    NSLog(@"Error updating token: %@", error);
}

- (void)logout {
    [self storeIdentity:nil];
    [self.client shutdown];
    self.client = nil;
    self.accessManager = nil;
}

- (void)updatePushToken:(NSData *)token {
    self.lastToken = token;
    [self updateIpMessagingClient];
}

- (void)receivedNotification:(NSDictionary *)notification {
    self.lastNotification = notification;
    [self updateIpMessagingClient];
}

- (NSString *)identity {
    return [[[self client] userInfo] identity];
}

#pragma mark Push functionality

- (void)setIpMessagingClient:(TwilioIPMessagingClient *)ipMessagingClient {
    [self updateIpMessagingClient];
}

- (void)updateIpMessagingClient {
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
