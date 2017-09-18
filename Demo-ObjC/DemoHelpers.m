//
//  DemoHelpers.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>

#import "DemoHelpers.h"

@interface DemoHelpers()
@property (nonatomic, strong) NSMutableDictionary <NSString *, UIImage *> *imageCache;
@property (nonatomic, strong) NSMapTable <NSString *, dispatch_queue_t> *downloadQueues;
@end

@implementation DemoHelpers

- (instancetype)init {
    if ((self = [super init]) != nil) {
        self.imageCache = [NSMutableDictionary dictionary];
        self.downloadQueues = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                    valueOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static DemoHelpers *sharedHelpers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelpers = [[self alloc] init];
    });
    return sharedHelpers;
}

+ (void)displayToastWithMessage:(NSString *)message
                         inView:(UIView *)view {
    __block UIView *toastView = [self createMessagePopup:message
                                                  inView:view];
    
    [UIView animateWithDuration:1.25f delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         toastView.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:1.25f delay:1.0f
                                             options:UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              toastView.alpha = 0.0f;
                                          } completion:^(BOOL finished) {
                                              toastView.hidden = YES;
                                              [toastView removeFromSuperview];
                                              toastView = nil;
                                          }];
                     }];
}

+ (UIView *)displayMessage:(NSString *)message
                    inView:(UIView *)view {
    UIView *toastView = [self createMessagePopup:message
                                                  inView:view];
    
    [UIView animateWithDuration:1.25f delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         toastView.alpha = 1.0f;
                     } completion:nil];
    
    return toastView;
}

+ (NSString *)displayNameForUser:(TCHUser *)user {
    NSString *displayName = nil;
    NSString *friendlyName = [user friendlyName];
    if (friendlyName && ![friendlyName isEqualToString:@""]) {
        displayName = friendlyName;
    } else {
        displayName = [user identity];
    }
    return displayName;
}

+ (NSString *)messageDisplayForDate:(NSDate *)date {
    if (!date) {
        return @"";
    }
    
    NSDateFormatter *formatter = nil;
    if ([[NSCalendar currentCalendar] isDateInToday:date]) {
        formatter = [self cachedDateFormatterWithKey:@"DemoDateFormatter-Today"
                                         initializer:^(NSDateFormatter *formatter) {
                                             [formatter setTimeZone:[NSTimeZone defaultTimeZone]];
                                             formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hma" options:0 locale:formatter.locale];
                                         }];
    } else {
        formatter = [self cachedDateFormatterWithKey:@"DemoDateFormatter-AnyDay"
                                         initializer:^(NSDateFormatter *formatter) {
                                             [formatter setTimeZone:[NSTimeZone defaultTimeZone]];
                                             formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd, hma" options:0 locale:formatter.locale];
                                         }];
    }
    return [formatter stringFromDate:date];
}

+ (UIImage *)avatarForAuthor:(NSString *)author
                        size:(NSUInteger)size
               scalingFactor:(CGFloat)scale {
    return [self avatarForEmail:nil identity:author size:size scalingFactor:scale];
}

+ (UIImage *)avatarForUser:(TCHUser *)user
                      size:(NSUInteger)size
             scalingFactor:(CGFloat)scale {
    NSString *email = user.attributes[@"email"];
    NSString *identity = user.identity;
    
    UIImage *image = [self avatarForEmail:email identity:identity size:size scalingFactor:scale];
    
    if (user.isOnline) {
        image = [self addIndicatorToAvatar:image color:[UIColor greenColor]];
    } else if (user.isNotifiable) {
        image = [self addIndicatorToAvatar:image color:[UIColor lightGrayColor]];
    }
    
    return image;
}

+ (UIImage *)avatarForEmail:(NSString *)email
                   identity:(NSString *)identity
                       size:(NSUInteger)size
              scalingFactor:(CGFloat)scale {
    NSMutableDictionary *imageCache = [[self sharedInstance] imageCache];
    NSString *cacheKey = [NSString stringWithFormat:@"%@:%@", email, identity];
    UIImage *avatarImage = imageCache[cacheKey];
    if (!avatarImage) {
        if (email && ![email isEqualToString:@""]) {
            avatarImage = [self gravatarForEmail:email
                                            size:size
                                   scalingFactor:scale];
            imageCache[cacheKey] = avatarImage;
        }
        if (!avatarImage) {
            avatarImage = [self randomAvatarForIdentity:identity
                                                   size:size
                                          scalingFactor:scale];
            imageCache[cacheKey] = avatarImage;
        }
    }
    return avatarImage;
}

+ (NSMutableDictionary *)deepMutableCopyOfDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        return [[NSMutableDictionary alloc] init];
    }
    
    return (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                                                 (CFDictionaryRef)dictionary,
                                                                                 kCFPropertyListMutableContainers));
}

+ (void)reactionIncrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity {
    NSMutableDictionary *attributes = [DemoHelpers deepMutableCopyOfDictionary:message.attributes];
    if (!attributes) {
        attributes = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *reactionDict = [DemoHelpers reactionDictForReaction:emojiString inAttributes:attributes];
    
    if (![reactionDict[@"users"] containsObject:identity]) {
        [reactionDict[@"users"] addObject:identity];
        
        [message setAttributes:attributes
                    completion:^(TCHResult *result) {
                        if (!result.isSuccessful) {
                            NSLog(@"error occurred incrementing reaction: %@", emojiString);
                        }
                    }];
    }
}

+ (void)reactionDecrement:(NSString *)emojiString message:(TCHMessage *)message user:(NSString *)identity {
    NSMutableDictionary *attributes = [DemoHelpers deepMutableCopyOfDictionary:message.attributes];
    if (!attributes) {
        attributes = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *reactionDict = [DemoHelpers reactionDictForReaction:emojiString inAttributes:attributes];
    NSMutableArray *users = reactionDict[@"users"];
    
    if ([users containsObject:identity]) {
        [users removeObject:identity];
        
        if (users.count == 0) {
            [attributes[@"reactions"] removeObject:reactionDict];
        }
        
        [message setAttributes:attributes
                    completion:^(TCHResult *result) {
                        if (!result.isSuccessful) {
                            NSLog(@"error occurred decrementing reaction: %@", emojiString);
                        }
                    }];
    }
}

+ (void)unconsumedMessagesForChannel:(nonnull TCHChannel *)channel
                          completion:(nonnull TCHCountCompletion)completion {
    if (channel.synchronizationStatus < TCHChannelSynchronizationStatusAll || !channel.messages) {
        completion([[TCHResult alloc] init], 0);
        return;
    }
    
    if (channel.messages.lastConsumedMessageIndex) { // if the user has consumed any messages, the count is good as-is
        [channel getUnconsumedMessagesCountWithCompletion:completion];
    } else { // otherwise display total message count for the channel
        [channel getMessagesCountWithCompletion:completion];
    }
}

+ (UIImage *)cachedImageForMessage:(TCHMessage *)message {
    NSString *finalFilename = [self mediaFilenameForMessage:message];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:finalFilename]) {
        return [UIImage imageWithContentsOfFile:finalFilename];
    }
    
    return nil;
}

+ (void)loadImageForMessage:(TCHMessage *)message
             progressUpdate:(void(^)(CGFloat progress))progressUpdate
                 completion:(void(^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *cachedImage = [self cachedImageForMessage:message];
        if (cachedImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(cachedImage);
            });
            return;
        }
        
        dispatch_queue_t queue = nil;
        @synchronized (self) {
            queue = [[DemoHelpers sharedInstance].downloadQueues objectForKey:message.mediaSid];
            if (!queue) {
                NSString *queueName = [NSString stringWithFormat:@"Download %@", message.mediaSid];
                queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], nil);
                [[DemoHelpers sharedInstance].downloadQueues setObject:queue forKey:message.mediaSid];
            }
        }

        dispatch_async(queue, ^{
            UIImage *cachedImage = [self cachedImageForMessage:message];
            if (cachedImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(cachedImage);
                });
                return;
            }

            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); // Keep asynchronous getMediaWithOutputStream: call from allowing our serial queue to process the next request for this same download

            NSString *finalFilename = [self mediaFilenameForMessage:message];
            
            NSString *tempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], [finalFilename lastPathComponent]]];
            
            NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:tempFilename append:NO];
            [message getMediaWithOutputStream:outputStream
                                    onStarted:^{
                                        progressUpdate(0.0);
                                    } onProgress:^(NSUInteger bytes) {
                                        progressUpdate((CGFloat)bytes / (CGFloat)message.mediaSize);
                                    } onCompleted:^(NSString * _Nonnull mediaSid) {
                                        progressUpdate(1.0);
                                    } completion:^(TCHResult * _Nonnull result) {
                                        dispatch_queue_t thisQueue = queue; // keep queue alive until we're done
                                        if (result.isSuccessful) {
                                            if (![[NSFileManager defaultManager] fileExistsAtPath:finalFilename]) {
                                                NSError *error = nil;
                                                [[NSFileManager defaultManager] moveItemAtPath:tempFilename
                                                                                        toPath:finalFilename
                                                                                         error:&error];
                                                
                                                if (error) {
                                                    NSLog(@"Error renaming final file to %@ - %@", finalFilename, error);
                                                }
                                            }
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                completion([UIImage imageWithContentsOfFile:finalFilename]);
                                            });
                                        } else {
                                            NSLog(@"Download failed, cleaning up file: %@", result.error);
                                            NSError *deleteError = nil;
                                            [[NSFileManager defaultManager] removeItemAtPath:tempFilename
                                                                                       error:&deleteError];
                                            if (deleteError) {
                                                NSLog(@"Unable to delete failed download");
                                            }
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                completion(nil);
                                            });
                                        }
                                        thisQueue = nil;
                                        dispatch_semaphore_signal(semaphore);
                                    }];
            
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * 60 * NSEC_PER_SEC));
        });
    });
}

+ (UIImage *)image:(UIImage *)image scaledToWith:(CGFloat)width {
    if (image.size.width <= width) {
        return image;
    }
    
    CGFloat aspectRatio = width / image.size.width;
    CGSize newSize = CGSizeMake(image.size.width * aspectRatio, image.size.height * aspectRatio);
    
    UIGraphicsBeginImageContextWithOptions( newSize, NO, 0 );
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

#pragma mark - Internal helper methods

+ (NSDateFormatter *)cachedDateFormatterWithKey:(NSString *)cacheKey
                                    initializer:(void (^)(NSDateFormatter *formatter))initializer {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *formatter = threadDictionary[cacheKey];
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        initializer(formatter);
        threadDictionary[cacheKey] = formatter;
    }
    return formatter;
}

+ (NSString *)md5ForString:(NSString *)input {
    NSMutableString *ret = nil;
    if (input) {
        unsigned char md5[CC_MD5_DIGEST_LENGTH];
        [self md5ForString:input output:md5];
        ret = [NSMutableString string];
        for (int ndx=0; ndx < CC_MD5_DIGEST_LENGTH; ndx++) {
            [ret appendFormat:@"%02x", md5[ndx]];
        }
    }
    return ret;
}

+ (void)md5ForString:(NSString *)input output:(unsigned char *)output {
    if (input) {
        const char *inputCString = [input UTF8String];
        CC_MD5(inputCString, (CC_LONG)strlen(inputCString), output);
    }
}

+ (UIImage *)gravatarForEmail:(NSString *)email
                         size:(NSUInteger)size
                scalingFactor:(CGFloat)scale {
    NSString *emailHash = [self md5ForString:email];
    NSString *avatarURLString = [NSString stringWithFormat:@"https://www.gravatar.com/avatar/%@?d=404&s=%ld", emailHash, (unsigned long)(size*scale)];
    NSURL *avatarURL = [NSURL URLWithString:avatarURLString];
    NSData *data = [NSData dataWithContentsOfURL:avatarURL];
    UIImage *avatarImage = [UIImage imageWithData:data scale:scale];

    CGSize imageSize = avatarImage.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, avatarImage.scale);
    CGRect bounds = (CGRect){CGPointZero, imageSize};
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:imageSize.height / 2.0f] addClip];
    [avatarImage drawInRect:bounds];
    avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return avatarImage;
}

+ (UIImage *)randomAvatarForIdentity:(NSString *)identity
                                size:(NSUInteger)size
                       scalingFactor:(CGFloat)scale {
    UIImage *avatarImage = nil;
    
    CGRect bounds = (CGRect){CGPointZero, CGSizeMake(size, size)};
    UIGraphicsBeginImageContext(bounds.size);
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:bounds.size.height / 2.0f] addClip];
    
    UIColor *color = nil;
    if (identity) {
        unsigned char md5[CC_MD5_DIGEST_LENGTH];
        [self md5ForString:identity output:md5];
        color = [UIColor colorWithRed:(md5[0] / 255.0)
                                green:(md5[1] / 255.0)
                                 blue:(md5[2] / 255.0)
                                alpha:1.0f];
    } else {
        color = [UIColor colorWithWhite:0.9f alpha:1.0f];
    }
    
    UIImage *twilioLogo = [UIImage imageNamed:@"user-44px"];
    twilioLogo = [twilioLogo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGSize imageSize = twilioLogo.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, twilioLogo.scale);
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:imageSize.height / 2.0f] addClip];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, bounds);

    [[UIColor colorWithWhite:0.0f
                       alpha:0.5f] set];
    [twilioLogo drawInRect:bounds];
    
    avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return avatarImage;
}

+ (UIImage *)addIndicatorToAvatar:(UIImage *)sourceImage color:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(sourceImage.size, NO, sourceImage.scale);

    UIBezierPath *indicator = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1, 1, 5, 5)
                                                           cornerRadius:sourceImage.size.height / 2.0f];
    [color setFill];
    [indicator fill];

    [sourceImage drawAtPoint:CGPointMake(0, 0)];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSMutableDictionary *)reactionDictForReaction:(NSString *)emojiString inAttributes:(NSMutableDictionary *)attributes {
    NSMutableArray *reactions = attributes[@"reactions"];
    if (!reactions) {
        reactions = [NSMutableArray array];
        attributes[@"reactions"] = reactions;
    }
    NSMutableDictionary *reactionDict = nil;
    for (NSMutableDictionary *reactionDictCandidate in reactions) {
        if ([reactionDictCandidate[@"reaction"] isEqualToString:emojiString]) {
            reactionDict = reactionDictCandidate;
            break;
        }
    }
    
    if (!reactionDict) {
        reactionDict = [@{
                          @"reaction": emojiString,
                          @"users": [NSMutableArray array]
                          } mutableCopy];
        [reactions addObject:reactionDict];
    }
    
    return reactionDict;
}

+ (UIView *)createMessagePopup:(NSString *)message
                        inView:(UIView *)view {
    __block UIView *toastView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 100.0)];
    toastView.backgroundColor = [UIColor blueColor];
    toastView.layer.cornerRadius = 5.0f;
    UILabel *toastViewLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [toastView addSubview:toastViewLabel];
    [view addSubview:toastView];
    
    [toastView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [toastViewLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastViewLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastViewLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                        attribute:NSLayoutAttributeLeading
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeLeading
                                                       multiplier:1.0
                                                         constant:8.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                        attribute:NSLayoutAttributeTrailing
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeTrailing
                                                       multiplier:1.0
                                                         constant:-8.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:8.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastViewLabel
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationLessThanOrEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0
                                                         constant:-8.0]];
    [toastView addConstraints:constraints];
    
    toastViewLabel.numberOfLines = 0;
    toastViewLabel.textAlignment = NSTextAlignmentCenter;
    toastViewLabel.textColor = [UIColor whiteColor];
    toastViewLabel.text = message;
    toastView.alpha = 0.0f;
    toastView.hidden = NO;
    
    constraints = [NSMutableArray array];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toastView
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:nil
                                                        attribute:0
                                                       multiplier:0.0
                                                         constant:100.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:toastView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:0
                                                       multiplier:0.0
                                                         constant:250.0]];
    [view addConstraints:constraints];
    
    [toastView setNeedsLayout];
    
    return toastView;
}

+ (NSString *)mediaFilenameForMessage:(TCHMessage *)message {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = cacheDirectory;
    return [mediaDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", message.mediaSid, message.mediaFilename ? message.mediaFilename : @"attachment.dat"]];
}

@end
