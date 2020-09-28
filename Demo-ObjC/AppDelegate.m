//
//  AppDelegate.m
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatManager.h"
@import UserNotifications;

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Skipping push registration since we're in the simulator.");
#else
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                                                                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
            NSLog(@"access granted %@", granted ? @"YES" : @"NO");
        }];
        UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    } else {
        NSDictionary* localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (localNotification) {
            [self application:application didReceiveRemoteNotification:localNotification];
        }

        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    }
    [application registerForRemoteNotifications];
#endif

    [[ChatManager sharedManager] presentRootViewController];
    
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [[ChatManager sharedManager] updatePushToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    NSLog(@"Failed to get token, error: %@", error);
    [[ChatManager sharedManager] updatePushToken:nil];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if(notificationSettings.types == UIUserNotificationTypeNone) {
        NSLog(@"Failed to get token, error: Notifications are not allowed");
        [[ChatManager sharedManager] updatePushToken:nil];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // If your application supports multiple types of push notifications, you may wish to limit which ones you send to the TwilioConversationsClient here
    [[ChatManager sharedManager] receivedNotification:userInfo];
}

@end
