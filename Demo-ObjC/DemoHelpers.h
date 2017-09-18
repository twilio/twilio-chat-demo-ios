//
//  DemoHelpers.h
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <TwilioChatClient/TwilioChatClient.h>
#import <TwilioChatClient/TCHUser.h>

/** A collection of helper methods used by the Twilio Programmable Chat demo application. */
@interface DemoHelpers : NSObject

/** Simple toast machanism for displaying a temporary message to the user.
 
 @param message The text message to display.
 @param view The parent view of the toast popup.
 */
+ (void)displayToastWithMessage:(nonnull NSString *)message
                         inView:(nonnull UIView *)view;

/** Simple message popup machanism for displaying a message to the user you are responsible for dismissing.
 
 @param message The text message to display.
 @param view The parent view of the message popup.
 */
+ (nonnull UIView *)displayMessage:(nonnull NSString *)message
                            inView:(nonnull UIView *)view;

/** Determine a display name given a TCHUser object.
 
 This will prefer the friendlyName, if set, otherwise fallback to the user's identity.
 
 @param user The TCHUser object to evaluate.
 @return A display name for this user.
 */
+ (nullable NSString *)displayNameForUser:(nonnull TCHUser *)user;

/** Create a formatted display value for the given Date.
 
 If the date falls in the current day, omit the date portion for display.
 
 @param date
 @return The formatted display text for this date.
 */
+ (nonnull NSString *)messageDisplayForDate:(nonnull NSDate *)date;

/** Generate or download an avatar for the given user.
 
 If the TCHUser provided has a userInfo property set for `email`, it will be used to obtain an avatar from Gravatar.
 
 If the email is absent or unmatched by Gravatar, we will fall back to the behavior of avatarForAuthor:size:scalingFactor: which is to use the identity string to generate a random avatar.
 
 @param user The TCHUser to use when obtaining or generating the avatar.
 @param size The desired size (used for both width and height) of the returned image.
 @param scale The UI scaling factor to use (typically 2.0 for many retina displays).
 */
+ (nonnull UIImage *)avatarForUser:(nonnull TCHUser *)user
                              size:(NSUInteger)size
                     scalingFactor:(CGFloat)scale;

/** Generate or download an avatar for the given author (identity).
 
 In the event the author of a message is no longer a member of the channel, we will not have a TCHUser object to use for avatar generation.  Use the author (identity) to randomly generate an avatar.
 
 @param author The author (identity) to use when generating the avatar.
 @param size The desired size (used for both width and height) of the returned image.
 @param scale The UI scaling factor to use (typically 2.0 for many retina displays).
 */
+ (nonnull UIImage *)avatarForAuthor:(nonnull NSString *)author
                                size:(NSUInteger)size
                       scalingFactor:(CGFloat)scale;

/** Helper method to generate a deep mutable copy of the specified dictionary.
 
 When mutating userInfo on channels or users in Programmable Chat, it is often handy to get a mutable copy of the dictionary.  By default, NSDictionary's `mutableCopy` method only makes mutable the specified dictionary, not any values whose type are NSArray or NSDictionary.  This method uses a core foundation method to create a truly deep copy.
 
 @param dictionary The input (presumed immutable) dictionary.
 @return A deep mutable copy of the supplied dictionary.
 */
+ (nonnull NSMutableDictionary *)deepMutableCopyOfDictionary:(nullable NSDictionary *)dictionary;

/** Adds the specified identity as having reacted to a message with the given emojiString.
 
 Messages within Programmable Chat may have developer defined userInfo attributes.  We make use of such attributes in the demo application to support users reacting to a message.
 
 When a user reacts to a message with a given emojiString, we make a new entry in a dictionary on the message's userInfo of the format:
 `"reactions": [
    {
        "reaction": <emojiString>,
        "users": [
            @"alice",
            @"bob"
        ]
    }
 ]`
 
 As users react (or remove their reaction) the items in 'users' are updated to include or remove their identity.  The first user to react with a given emojiString creates a new entry in the reactions array.  The last user to remove their reaction likewise deletes that array.
 
 @param emojiString The text name of the emoji to display.
 @param message The message to modify the reaction on.
 @param identity The identity of the user reacting to the message.
 @see reactionDecrement:message:user:
 */
+ (void)reactionIncrement:(nonnull NSString *)emojiString
                  message:(nonnull TCHMessage *)message
                     user:(nonnull NSString *)identity;

/** Removes the specified identity as having reacted to a message with the given emojiString.
 
 More details can be found in `reactionIncrement:message:user:`
 
 @param emojiString The text name of the emoji to display.
 @param message The message to modify the reaction on.
 @param identity The identity of the user reacting to the message.
 @see reactionIncrement:message:user:
 */
+ (void)reactionDecrement:(nonnull NSString *)emojiString
                  message:(nonnull TCHMessage *)message
                     user:(nonnull NSString *)identity;

/** Helper to simplify the display of unconsumed messages for the current user on a channel.
 
 Today, `getUnconsumedMessagesCountWithCompletion:` will return 0 in the event the user does not have a consumption status on the channel.  This can occur if the user is a brand new member of a channel or after calling TCHMessages' `setNoMessagesConsumed`.
 
 This method temporarily works around that by checking if the user has a consumption status on the channel and, if not, returns the total message count on the channel instead.
 
 Note that this will still return a count of 0 if called before the channel is fully synchronized so care should be taken to use the value only if the channel is synchronized.
 
 @param channel The channel to request the count for.
 @param completion The completion block which will receive the response.
 */
+ (void)unconsumedMessagesForChannel:(nonnull TCHChannel *)channel
                          completion:(nonnull TCHCountCompletion)completion;

/** Load image from cache, if it exists locally.
 
 @param message The TCHMessage whose media to load from the cache, if present.
 @return The UIImage associated with the TCHMessage, if we have it cached locally otherwise nil.
 */
+ (nullable UIImage *)cachedImageForMessage:(nonnull TCHMessage *)message;

/** Download the media for the given TCHMessage.
 
 This method wraps the standard media fetching method on TCHMessage with the following functionality:
 - Will fulfill the image request from cache, if the media is present locally.
 - Prevents multiple simultaneous downloads from occuring, allowing one download to occur at a time and keeping other requests queued to either be fulfilled by the result of the current download or attempt the download again if it fails.  If the media operation takes more than 5 minutes, the operation will be assumed to be failed and allow the next request in line to complete.
 
 The queueing behavior only applies to repeat requests for the same piece of media - multiple requests on multiple TCHMessage objects will be executed simultaneously.
 
 @param message The TCHMessage for which to load the media.
 @param progressUpdate Update block which will be called with the number of bytes downloaded so far.
 @param completion Completion block which will be called with the image if the operation is successful or nil if unsuccessful.
 */
+ (void)loadImageForMessage:(nonnull TCHMessage *)message
             progressUpdate:(void(^_Nonnull)(CGFloat progress))progressUpdate
                 completion:(void(^_Nonnull)(UIImage * _Nullable image))completion;

/** Helper to scale the given image to fit the specified width.
 
 @param image The image to scale
 @param width The desired width, if narrower than the current image width we will not scale the image up.
 @return The scaled (or original) image.
 */
+ (nonnull UIImage *)image:(nonnull UIImage *)image
              scaledToWith:(CGFloat)width;

@end
