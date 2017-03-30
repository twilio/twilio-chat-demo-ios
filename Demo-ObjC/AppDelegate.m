//
//  AppDelegate.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

    NSDictionary* localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (localNotification) {
        [self application:application didReceiveRemoteNotification:localNotification];
    }

    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];

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
    // If your application supports multiple types of push notifications, you may wish to limit which ones you send to the TwilioChatClient here
    [[ChatManager sharedManager] receivedNotification:userInfo];
}

@end
