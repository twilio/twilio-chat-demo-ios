//
//  ChannelViewController.h
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioConversationsClient/TwilioConversationsClient.h>

@interface ChannelViewController : UIViewController
@property (nonatomic, strong) TCHConversation *channel;
@end
