//
//  ChannelViewController.h
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioChatClient/TwilioChatClient.h>

@interface ChannelViewController : UIViewController
@property (nonatomic, strong) TCHChannel *channel;
@end
