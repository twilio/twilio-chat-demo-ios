//
//  PublicChannelListViewController.h
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioConversationsClient/TwilioConversationsClient.h>

@interface PublicChannelListViewController : UIViewController

@property (nonatomic, strong) TCHConversationDescriptorPaginator *paginator;

@end
