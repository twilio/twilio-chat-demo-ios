//
//  ImageMessageTableViewCell.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import "ImageMessageTableViewCell.h"
#import "ReactionsView.h"
#import "DemoHelpers.h"
#import "ChatManager.h"

@interface ImageMessageTableViewCell() <ReactionViewDelegate>
@property (nonatomic, weak) UILabel *authorLabel;
@property (nonatomic, weak) UILabel *dateLabel;
@property (nonatomic, weak) UIImageView *avatarImage;
@property (nonatomic, weak) ReactionsView *reactionsView;
@end

@implementation ImageMessageTableViewCell

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

    UIImageView *messageImageView = [[UIImageView alloc] init];
    messageImageView.translatesAutoresizingMaskIntoConstraints = NO;
    messageImageView.contentMode = UIViewContentModeScaleAspectFit;
    components[@"body"] = messageImageView;
    [self addSubview:messageImageView];
    self.messageImageView = messageImageView;
    
    UIProgressView *progressView = [[UIProgressView alloc] init];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.progress = 0.0f;
    self.progressView = progressView;
    
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showProgress {
    NSDictionary<NSString *, id> *metrics = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, UIView *> *components = [NSMutableDictionary dictionary];

    components[@"author"] = self.authorLabel;
    components[@"progress"] = self.progressView;
    components[@"body"] = self.messageImageView;
    components[@"reactions"] = self.reactionsView;

    [self addSubview:self.progressView];
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[progress]-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[progress(>=3)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[progress]-[body]"
                                                                             options:NSLayoutFormatAlignAllTop
                                                                             metrics:metrics
                                                                               views:components]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[progress]-[body]"
                                                                             options:NSLayoutFormatAlignAllLeading
                                                                             metrics:metrics
                                                                               views:components]];
    for (NSLayoutConstraint *constraint in constraints) {
        [constraint setPriority:UILayoutPriorityRequired];
    }
    [self addConstraints:constraints];

    [self.progressView setNeedsLayout];
    [self.progressView setNeedsDisplay];
    
    [self updateConstraints];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)hideProgress {
    [self.progressView removeFromSuperview];
    self.progressView.progress = 0.0f;
}

- (void)setMessage:(TCHMessage *)message {
    _message = message;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _message = message;
    
    if (message) {
        [[NSNotificationCenter defaultCenter] addObserverForName:@"MediaProgressUpdate"
                                                          object:message
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          CGFloat progress = [note.userInfo[@"progress"] floatValue];
                                                          [self.progressView setProgress:progress animated:YES];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"MediaProgressImage"
                                                          object:message
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          UIImage *image = note.userInfo[@"image"];
                                                          UITableView *tableView = note.userInfo[@"tableView"];
                                                          
                                                          self.messageImageView.image = image;
                                                          [tableView reloadData];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"MediaProgressHide"
                                                          object:message
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [self hideProgress];
                                                      }];
    }

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
    self.authorLabel.text = @"";
    self.dateLabel.text = @"";
    [self.messageImageView setImage:nil];
    [self hideProgress];
    self.message = nil;
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
