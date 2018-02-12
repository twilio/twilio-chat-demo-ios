//
//  MessageTableViewCell.h
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioChatClient/TwilioChatClient.h>

@protocol MessageTableViewCellDelegate;

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) TCHChannel *channel;
@property (nonatomic, strong) TCHMessage *message;
@property (nonatomic, assign) id<MessageTableViewCellDelegate> delegate;

@end

@protocol MessageTableViewCellDelegate <NSObject>
- (void)reactionIncremented:(NSString *)emojiString
                    message:(TCHMessage *)message;
- (void)reactionDecremented:(NSString *)emojiString
                    message:(TCHMessage *)message;
- (void)showUsersForReaction:(NSString *)emojiString
                     message:(TCHMessage *)message;
@end
