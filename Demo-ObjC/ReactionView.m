//
//  ReactionView.m
//  Demo-ObjC
//
//  Created by Randy Beiter on 6/26/16.
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ReactionView.h"

@interface ReactionView()
@property (nonatomic, strong) UILabel *actionButton;
@property (nonatomic, strong) UILabel *emojiLabel;
@property (nonatomic, strong) UILabel *countLabel;
@end

@implementation ReactionView

+ (NSDictionary *)emojis {
    static NSDictionary *emojis = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emojis = @{
                   @"thumbs_up_sign": @"👍",
                   @"thumbs_down_sign": @"👎",
                   @"slightly_smiling_face": @"🙂",
                   @"grinning_face": @"😀",
                   @"winking_face": @"😉"
                   };
    });
    return emojis;
}

+ (NSString *)friendlyNameForEmoji:(NSString *)emojiString {
    return [[emojiString stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self sharedDefaults];
        [self configureSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedDefaults];
        [self configureSubviews];
    }
    return self;
}

- (void)sharedDefaults {
    self.emojiString = @"";
    self.count = 0;
    self.localUserReacted = NO;
}

- (void)configureSubviews {
    self.userInteractionEnabled = YES;
    
    [self addSubview:self.emojiLabel];
    [self addSubview:self.countLabel];
    [self addSubview:self.actionButton];
    
    NSDictionary *views = @{
                            @"emojiLabel": self.emojiLabel,
                            @"countLabel": self.countLabel,
                            @"actionButton": self.actionButton
                            };
    
    NSDictionary *metrics = @{
                              @"top": @4,
                              @"leading": @4,
                              @"trailing": @4,
                              @"bottom": @4,
                              @"padding": @4
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leading-[emojiLabel]-padding-[countLabel]-trailing-|"
                                                                options:0
                                                                metrics:metrics
                                                                  views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top@999-[emojiLabel]-bottom@999-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top@999-[countLabel]-bottom@999-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionButton]-0-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[actionButton]-0-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0f;
    if (@available(iOS 13.0, *)) {
        self.layer.borderColor = UIColor.systemGray3Color.CGColor;
    } else {
        self.layer.borderColor = UIColor.lightGrayColor.CGColor;
    }

    [self setNeedsLayout];
}

- (void)setEmojiString:(NSString *)emojiString {
    _emojiString = emojiString;
    self.emojiLabel.text = [ReactionView emojis][emojiString];
    [self setNeedsLayout];
}

- (void)setCount:(NSUInteger)count {
    _count = count;
    self.countLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.count];
    [self setNeedsLayout];
}

- (void)setLocalUserReacted:(BOOL)localUserReacted {
    _localUserReacted = localUserReacted;
    if (self.localUserReacted) {
        self.backgroundColor = [UIColor colorWithHue:0.2 saturation:0.2 brightness:0.9 alpha:1.0];
    } else {
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = UIColor.systemBackgroundColor;
        } else {
            self.backgroundColor = UIColor.whiteColor;
        }
    }
    [self setNeedsDisplay];
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    self.emojiString = @"slightly_smiling_face";
    self.count = 42;
    self.localUserReacted = YES;
    [self configureSubviews];
}

- (UILabel *)emojiLabel {
    if (!_emojiLabel) {
        _emojiLabel = [UILabel new];
        _emojiLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _emojiLabel.backgroundColor = [UIColor clearColor];
        _emojiLabel.userInteractionEnabled = NO;
        _emojiLabel.numberOfLines = 1;
        _emojiLabel.textAlignment = NSTextAlignmentCenter;
        _emojiLabel.font = [UIFont systemFontOfSize:10.0f];
    }
    return _emojiLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [UILabel new];
        _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.userInteractionEnabled = NO;
        _countLabel.numberOfLines = 1;
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.font = [UIFont boldSystemFontOfSize:10.0f];
    }
    return _countLabel;
}

- (UILabel *)actionButton {
    if (!_actionButton) {
        _actionButton = [UILabel new];
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        _actionButton.userInteractionEnabled = YES;

        UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
        [longPress addTarget:self action:@selector(longPressed:)];
        [_actionButton addGestureRecognizer:longPress];

        UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
        [tap addTarget:self action:@selector(tapped:)];
        [_actionButton addGestureRecognizer:tap];
    }
    return _actionButton;
}

- (void)tapped:(UIGestureRecognizer *)gestureRecognizer {
    [UIView animateWithDuration:0.5 animations:^{
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = UIColor.systemGray5Color;
        } else {
            self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        }
    } completion:nil];

    if (self.localUserReacted) {
        if (self.delegate) {
            [self.delegate reactionDecremented:self.emojiString];
        }
    } else {
        if (self.delegate) {
            [self.delegate reactionIncremented:self.emojiString];
        }
    }
}

- (void)longPressed:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate) {
            [self.delegate showUsersForReaction:self.emojiString];
        }
    }
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

@end
