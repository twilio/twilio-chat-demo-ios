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
@property (nonatomic, weak) UILabel *authorLabel;
@property (nonatomic, weak) UILabel *dateLabel;
@property (nonatomic, weak) UILabel *bodyLabel;
@property (nonatomic, weak) UIImageView *avatarImage;
@property (nonatomic, weak) ReactionsView *reactionsView;
@end

@implementation MessageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
        [self sharedInit];
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedInit];
    }
    
    return self;
}

- (void)sharedInit {
    NSDictionary<NSString *, id> *metrics = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, UIView *> *components = [NSMutableDictionary dictionary];
    
    UIImageView *avatarImage = [[UIImageView alloc] init];
    avatarImage.translatesAutoresizingMaskIntoConstraints = NO;
    components[@"avatar"] = avatarImage;
    [self addSubview:avatarImage];
    self.avatarImage = avatarImage;
    
    UILabel *authorLabel = [[UILabel alloc] init];
    authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [authorLabel setFont:[UIFont boldSystemFontOfSize:13.0f]];
    components[@"author"] = authorLabel;
    [self addSubview:authorLabel];
    self.authorLabel = authorLabel;
    
    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [dateLabel setFont:[UIFont systemFontOfSize:13.0f weight:UIFontWeightThin]];
    components[@"date"] = dateLabel;
    [self addSubview:dateLabel];
    self.dateLabel = dateLabel;
    
    UILabel *bodyLabel = [[UILabel alloc] init];
    bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [bodyLabel setFont:[UIFont systemFontOfSize:17.0f]];
    bodyLabel.numberOfLines = 0;
    components[@"body"] = bodyLabel;
    [self addSubview:bodyLabel];
    self.bodyLabel = bodyLabel;
    
    ReactionsView *reactionsView = [[ReactionsView alloc] init];
    reactionsView.translatesAutoresizingMaskIntoConstraints = NO;
    components[@"reactions"] = reactionsView;
    [self addSubview:reactionsView];
    self.reactionsView = reactionsView;
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[avatar(44)]-[author]|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[date]-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[body]-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[reactions]-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[avatar(44)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[author]-[body]-[reactions]-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[date]-[body]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[author]-[body]-[reactions]"
                                                                             options:NSLayoutFormatAlignAllLeading
                                                                             metrics:metrics
                                                                               views:components]];
    
    [self addConstraints:constraints];
    [self setNeedsLayout];
    
    self.userInteractionEnabled = YES;
    self.reactionsView.delegate = self;
}

- (void)setMessage:(TCHMessage *)message {
    _message = message;
    
    [self configureDisplay];
}

- (void)configureDisplay {
    if (!self.message) {
        [self clearCell];
        return;
    }
    
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
    [self clearCell];
    self.delegate = nil;
    [super prepareForReuse];
}

- (void)clearCell {
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.reactionsView.reactions = @[];
    self.reactionsView.localIdentity = @"";
    self.authorLabel.text = @"";
    self.avatarImage.image = nil;
    self.dateLabel.text = @"";
    self.bodyLabel.text = @"";
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
