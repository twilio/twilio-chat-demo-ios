//
//  ImageMessageTableViewCell.h
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioChatClient/TwilioChatClient.h>

#import "MessageTableViewCell.h"

@interface ImageMessageTableViewCell : UITableViewCell

@property (nonatomic, strong) TCHChannel *channel;
@property (nonatomic, strong) TCHMessage *message;
@property (nonatomic, assign) id<MessageTableViewCellDelegate> delegate;

@property (nonatomic, weak) UIImageView *messageImageView;
@property (nonatomic, strong) UIProgressView *progressView;

- (void)showProgress;
- (void)hideProgress;

@end
