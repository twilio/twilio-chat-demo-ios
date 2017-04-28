//
//  ChatManager.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatManager.h"

#import <TwilioAccessManager/TwilioAccessManager.h>

@interface ChatManager() <TwilioAccessManagerDelegate, TwilioChatClientDelegate>
@property (nonatomic, strong) TwilioAccessManager *accessManager;
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
    if (![[ChatManager sharedManager] hasIdentity]) {
        [self presentLoginScreen];
        return;
    }

    if (self.client) {
        [self presentChannelsScreen];
        return;
    }

    [[ChatManager sharedManager] loginWithStoredIdentityWithCompletion:^(BOOL success) {
        if (success) {
            [self presentChannelsScreen];
        } else {
            [self presentLoginScreen];
        }
    }];
}

- (void)presentLoginScreen {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"login"];
}

- (void)presentChannelsScreen {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
}

- (BOOL)hasIdentity {
    return ([self storedIdentity] && [self storedIdentity].length > 0);
}

- (BOOL)loginWithStoredIdentityWithCompletion:(void(^)(BOOL success))completion {
    if ([self hasIdentity]) {
        return [self loginWithIdentity:[self storedIdentity] completion:completion];
    } else {
        return NO;
    }
}

- (BOOL)loginWithIdentity:(NSString *)identity completion:(void(^)(BOOL success))completion {
    if (self.client) {
        [self logout];
    }
    
    [self storeIdentity:identity];
    
    NSString *token = [self tokenForIdentity:identity];
    TwilioChatClientProperties *properties = [[TwilioChatClientProperties alloc] init];
    __weak typeof(self) weakSelf = self;
    [TwilioChatClient chatClientWithToken:token
                               properties:properties
                                 delegate:self
                               completion:^(TCHResult *result, TwilioChatClient *chatClient) {
                                   if ([result isSuccessful]) {
                                       self.client = chatClient;

                                       self.accessManager = [TwilioAccessManager accessManagerWithToken:token
                                                                                               delegate:weakSelf];
                                       
                                       __weak typeof(weakSelf.client) weakClient = weakSelf.client;
                                       [self.accessManager registerClient:self.client forUpdates:^(NSString * _Nonnull updatedToken) {
                                           [weakClient updateToken:updatedToken completion:^(TCHResult *result) {
                                               if (![result isSuccessful]) {
                                                   // retry token update or warn user
                                               }
                                           }];
                                       }];

                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [[ChatManager sharedManager] updateChatClient];
                                           completion(YES);
                                       });
                                   } else {
                                       // warn user
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           completion(NO);
                                       });
                                   }
                               }];

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
    return [[[self client] user] identity];
}

#pragma mark Push functionality

- (void)updateChatClient {
    if (self.client &&
        (self.client.synchronizationStatus == TCHClientSynchronizationStatusChannelsListCompleted ||
         self.client.synchronizationStatus == TCHClientSynchronizationStatusCompleted)) {
        if (self.lastToken) {
            [self.client registerWithNotificationToken:self.lastToken completion:^(TCHResult *result) {
                if ([result isSuccessful]) {

                } else {
                    // try again?
                }
            }];
        }
        
        if (self.lastNotification) {
            [self.client handleNotification:self.lastNotification completion:^(TCHResult *result) {
                if ([result isSuccessful]) {
                    self.lastNotification = nil;
                } else {
                    // try again?
                }
            }];
        }
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
    
#pragma mark - TwilioAccessManagerDelegate implementation
    
- (void)accessManagerTokenWillExpire:(nonnull TwilioAccessManager *)accessManager {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [accessManager updateToken:[self tokenForIdentity:[self identity]]];
    });
}
    
- (void)accessManagerTokenInvalid:(nonnull TwilioAccessManager *)accessManager {
    NSLog(@"error in token");
}

#pragma mark - TwilioChatClientDelegate temporary impl until channels list takes over

// Can occur before we transfer the delegate to the channels list VC
- (void)chatClient:(TwilioChatClient *)client notificationUpdatedBadgeCount:(NSUInteger)badgeCount {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
}

- (void)chatClient:(TwilioChatClient *)client errorReceived:(TCHError *)error {
    NSLog(@"error received: %@", error);
}
    
@end
