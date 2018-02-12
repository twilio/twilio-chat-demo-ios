//
//  ReactionsView.m
//  Demo-ObjC
//
//  Created by Randy Beiter on 6/26/16.
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import "ReactionsView.h"
#import "ReactionView.h"

@interface ReactionsView()
@property (nonatomic, strong) NSMutableArray *reactionViews;
@end

@implementation ReactionsView

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
    self.reactionViews = [NSMutableArray array];
    self.reactions = @[];
}

- (void)cleanupReactionViews {
    for (ReactionView *reactionView in self.reactionViews) {
        [reactionView removeFromSuperview];
    }
    [self.reactionViews removeAllObjects];
}

- (void)configureSubviews {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.masksToBounds = YES;
    
    self.backgroundColor = [UIColor clearColor];
    
    [self cleanupReactionViews];
    
    UIView *container = self;
    for (NSDictionary *reaction in self.reactions) {
        ReactionView *reactionView = [ReactionView new];
        reactionView.delegate = self.delegate;
        reactionView.translatesAutoresizingMaskIntoConstraints = NO;
        reactionView.emojiString = reaction[@"reaction"];
        NSArray *users = reaction[@"users"];
        reactionView.count = users.count;
        reactionView.localUserReacted = [users containsObject:self.localIdentity];
        [self.reactionViews addObject:reactionView];
        [container addSubview:reactionView];
    }

    // Set up auto-layout constraints

    NSUInteger count = self.reactionViews.count;
    if (count > 0) {
        NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:self.reactionViews.count];
        for (int i=0; i<count; i++) {
            NSString *key = [NSString stringWithFormat:@"view%d", i];
            views[key] = self.reactionViews[i];
        }

        NSDictionary *metrics = @{
                                  @"top": @4,
                                  @"leading": @4,
                                  @"trailing": @4,
                                  @"bottom": @4,
                                  @"padding": @8
                                  };

        NSMutableString *horizViews = [NSMutableString string];
        for (int i=0; i<count; i++) {
            NSString *vConstraint = [NSString stringWithFormat:@"V:|-top-[view%d]-bottom-|", i];
            [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:vConstraint options:0 metrics:metrics views:views]];
            
            if (i > 0) {
                [horizViews appendString:@"-padding"];
            }
            [horizViews appendFormat:@"-[view%d]", i];
        }
        NSString *hConstraint = [NSString stringWithFormat:@"H:|-leading%@-(>=trailing)-|", horizViews];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:hConstraint options:0 metrics:metrics views:views]];
    }
    
    [self setNeedsLayout];
}

- (void)setReactions:(NSArray *)reactions {
    _reactions = reactions;
    [self configureSubviews];
}

- (void)setDelegate:(id<ReactionViewDelegate>)delegate {
    _delegate = delegate;
    for (ReactionView *reactionView in self.reactionViews) {
        reactionView.delegate = self.delegate;
    }
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    [self sharedDefaults];
    self.reactions = @[
                       @{
                           @"reaction": @"slightly_smiling_face",
                           @"users": @[@"test1"]
                           },
                       @{
                           @"reaction": @"thumbs_up_sign",
                           @"users": @[@"test1", @"test2"]
                           }
                       ];
    self.localIdentity = @"test2";
    [self configureSubviews];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(0, 0);
}

@end
