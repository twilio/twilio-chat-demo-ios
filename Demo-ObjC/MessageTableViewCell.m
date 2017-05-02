//
//  MessageTableViewCell.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "ReactionsView.h"
#import "DemoHelpers.h"
#import "ChatManager.h"

@interface MessageTableViewCell() <ReactionViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *authorLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *bodyLabel;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImage;
@property (nonatomic, weak) IBOutlet ReactionsView *reactionsView;
@end

@implementation MessageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
    self.reactionsView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(TCHMessage *)message {
    _message = message;
    
    [self configureDisplay];
}

- (void)configureDisplay {
    TCHMember *author = [[self channel] memberWithIdentity:[self message].author];
    if (author) {
        [[[[ChatManager sharedManager] client] users] subscribedUserWithIdentity:author.identity
                                                                      completion:^(TCHResult *result, TCHUser *user) {
                                                                          if (result.isSuccessful) {
                                                                              self.authorLabel.text = [DemoHelpers displayNameForUser:user];
                                                                              self.avatarImage.image = [DemoHelpers avatarForUser:user size:44.0 scalingFactor:2.0];
                                                                          } else {
                                                                              self.authorLabel.text = self.message.author;
                                                                              self.avatarImage.image = [DemoHelpers avatarForAuthor:self.message.author size:44.0 scalingFactor:2.0];
                                                                          }
                                                                      }];
    } else {
        // original author may not exist anymore on channel, display the original username
        self.authorLabel.text = self.message.author;
        self.avatarImage.image = [DemoHelpers avatarForAuthor:self.message.author size:44.0 scalingFactor:2.0];
    }
    self.dateLabel.text = [DemoHelpers messageDisplayForDate:self.message.timestampAsDate];
    self.bodyLabel.text = self.message.body;
    NSArray *reactions = self.message.attributes[@"reactions"];
    if (reactions) {
        self.reactionsView.localIdentity = [self localIdentity];
        self.reactionsView.reactions = reactions;
    }
    if ([self.localIdentity isEqualToString:[self message].author]) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1.0f];
    }
}

- (void)prepareForReuse {
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.reactionsView.reactions = @[];
    self.delegate = nil;
}

- (NSString *)localIdentity {
    TCHUser *localUser = [[[ChatManager sharedManager] client] user];
    return localUser.identity;
}

#pragma mark - ReactionViewDelegate

- (void)reactionIncremented:(NSString *)emojiString {
    if (self.delegate) {
        [self.delegate reactionIncremented:emojiString
                                   message:self.message];
    }
}

- (void)reactionDecremented:(NSString *)emojiString {
    if (self.delegate) {
        [self.delegate reactionDecremented:emojiString
                                   message:self.message];
    }
}

- (void)showUsersForReaction:(NSString *)emojiString {
    if (self.delegate) {
        [self.delegate showUsersForReaction:emojiString
                                    message:self.message];
    }
}

@end
