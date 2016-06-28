//
//  MessageTableViewCell.h
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioIPMessagingClient/TwilioIPMessagingClient.h>

@protocol MessageTableViewCellDelegate;

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) TWMChannel *channel;
@property (nonatomic, strong) TWMMessage *message;
@property (nonatomic, assign) id<MessageTableViewCellDelegate> delegate;

@end

@protocol MessageTableViewCellDelegate <NSObject>
- (void)reactionIncremented:(NSString *)emojiString
                    message:(TWMMessage *)message;
- (void)reactionDecremented:(NSString *)emojiString
                    message:(TWMMessage *)message;
- (void)showUsersForReaction:(NSString *)emojiString
                     message:(TWMMessage *)message;
@end