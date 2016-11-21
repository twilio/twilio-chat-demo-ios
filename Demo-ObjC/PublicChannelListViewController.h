//
//  PublicChannelListViewController.h
//  Twilio Chat Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioChatClient/TwilioChatClient.h>

@interface PublicChannelListViewController : UIViewController

@property (nonatomic, strong) TCHChannelDescriptorPaginator *paginator;

@end
