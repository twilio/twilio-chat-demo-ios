//
//  ReactionView.h
//  Demo-ObjC
//
//  Created by Randy Beiter on 6/26/16.
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReactionViewDelegate;

IB_DESIGNABLE @interface ReactionView : UIView

@property (nonatomic, assign) id<ReactionViewDelegate> delegate;
@property (nonatomic, copy) NSString *emojiString;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) BOOL localUserReacted;

+ (NSDictionary *)emojis;
+ (NSString *)friendlyNameForEmoji:(NSString *)emojiString;

@end

@protocol ReactionViewDelegate <NSObject>
@optional
- (void)reactionIncremented:(NSString *)emojiString;
- (void)reactionDecremented:(NSString *)emojiString;
- (void)showUsersForReaction:(NSString *)emojiString;
@end
