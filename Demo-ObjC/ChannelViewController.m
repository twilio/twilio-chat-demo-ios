//
//  ChannelViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "ChannelViewController.h"
#import "MessageTableViewCell.h"
#import "MemberTypingTableViewCell.h"
#import "SeenByTableViewCell.h"
#import "DemoHelpers.h"
#import "IPMessagingManager.h"
#import "ReactionView.h"
#import "UserListViewController.h"

static NSString * const kChannelDataType = @"channelDataType";
static NSString * const kChannelDataTypeMessage = @"message";
static NSString * const kChannelDataTypeMemberConsumption = @"memberConsumption";
static NSString * const kChannelDataTypeUserConsumption = @"userConsumption";
static NSString * const kChannelDataTypeMembersTyping = @"membersTyping";
static NSString * const kChannelDataData = @"channelDataData";

@interface ChannelViewController () <UITableViewDataSource, UITableViewDelegate, TWMChannelDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, MessageTableViewCellDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAdjustmentConstraint;

@property (nonatomic, strong) NSMutableOrderedSet<TWMMessage *> *messages;
@property (nonatomic, strong) NSMutableArray<id> *channelData;
@property (nonatomic, strong) NSMutableArray *typingUsers;
@property (nonatomic, copy) NSNumber *userConsumedIndex;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSArray<TWMMember *> *> *seenBy;

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSNumber *> *cachedHeights;
@end

@implementation ChannelViewController

#pragma mark - View lifecycle methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.messages = [[NSMutableOrderedSet alloc] init];
    self.typingUsers = [NSMutableArray array];
    self.cachedHeights = [NSMutableDictionary dictionary];
}

- (void)updateChannel {
    NSNumber *lastConsumedMessageIndex = [self.channel.messages lastConsumedMessageIndex];
    
    if (lastConsumedMessageIndex && ![[[self.messages lastObject] index] isEqualToNumber:lastConsumedMessageIndex]) {
        self.userConsumedIndex = lastConsumedMessageIndex;
    }
    [self refreshSeenBy];
}

- (void)refreshSeenBy {
    NSMutableDictionary *seenBy = [NSMutableDictionary dictionary];
    for (TWMMember *member in [self.channel.members allObjects]) {
        if (![self isMe:member]) {
            NSNumber *index = [member lastConsumedMessageIndex];
            if (index) {
                NSMutableArray *members = seenBy[index];
                if (!members) {
                    members = [NSMutableArray array];
                    seenBy[index] = members;
                }
                if (![members containsObject:member]) {
                    [members addObject:member];
                }
            }
        }
    }

    self.seenBy = seenBy;
    [self rebuildData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
    [longPress addTarget:self action:@selector(messageActions:)];
    [self.tableView addGestureRecognizer:longPress];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.channel) {
        self.channel.delegate = self;
        [self loadMessages];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:self.view.window];
        
        [self.messageInput becomeFirstResponder];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self scrollToLastConsumedMessage];
    
    // load up the rest of the history for the channel
    TWMMessage *firstMessage = [self.messages firstObject];
    if (firstMessage && [firstMessage.index integerValue] > 0) {
        [self.channel.messages getMessagesBefore:([firstMessage.index integerValue] - 1)
                                       withCount:UINT_MAX
                                      completion:^(TWMResult *result, NSArray<TWMMessage *> *messages) {
                                          NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, messages.count)];
                                          [self.messages insertObjects:messages
                                                             atIndexes:indexes];
                                          [self rebuildData];
                                          [self scrollToLastConsumedMessage];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.channel) {
        self.channel.delegate = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setChannel:(TWMChannel *)channel {
    _channel = channel;
    self.channel.delegate = self;

    [self loadMessages];
    [self updateChannel];
}

- (void)messageActions:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }

    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    TWMMessage *message = [self messageForIndexPath:indexPath];

    UIAlertController *actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak __typeof(self) weakSelf = self;
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Edit Message"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeMessage:message];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Add Reaction"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf addReactionToMessage:message];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Delete Message"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf destroyMessage:message];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil]];
    
    [self presentViewController:actionsSheet
                       animated:YES
                     completion:nil];
}

- (IBAction)channelActions:(id)sender {
    UIAlertController *actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak __typeof(self) weakSelf = self;
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Channel Friendly Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeFriendlyName];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Channel Unique Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeUniqueName];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Channel Topic"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeTopic];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"List Members"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf listMembers];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Invite Member"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf inviteMember];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Add Member"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf addMember];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"My Friendly Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeMyFriendlyName];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Avatar Email"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeAvatarEmail];
                                                   }]];
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Leave"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf leaveChannel];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil]];
    
    [self presentViewController:actionsSheet
                       animated:YES
                     completion:nil];
}

#pragma mark - UITableViewDataSource

- (BOOL)showNewest {
    return (self.userConsumedIndex &&
            [self.userConsumedIndex integerValue] < [[[[self messages] lastObject] index] integerValue]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self channelData].count;
    if (self.typingUsers.count > 0) {
        count++;
    }
    return count;
}

- (NSString *)typingUsersString {
    NSArray *typingUsers = [self.typingUsers copy];
    NSString *membersString = [self pluralizeListOfMembers:typingUsers];
    
    return [NSString stringWithFormat:@"%@ %@ typing...", membersString, typingUsers.count > 1 ? @"are" : @"is"];
}

- (NSString *)pluralizeListOfMembers:(NSArray<TWMMember *> *)members {
    if (!members || [members count] == 0) {
        return @"";
    }
    
    NSMutableArray *memberDisplayNames = [NSMutableArray array];
    for (TWMMember *member in members) {
        [memberDisplayNames addObject:[DemoHelpers displayNameForMember:member]];
    }
    [memberDisplayNames sortUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableString *ret = [NSMutableString string];    
    for (int ndx=0; ndx < memberDisplayNames.count; ndx++) {
        NSString *displayName = memberDisplayNames[ndx];
        if (ndx > 0 && ndx < memberDisplayNames.count - 1) {
            [ret appendString:@", "];
        } else if (ndx > 0 && ndx == memberDisplayNames.count - 1) {
            [ret appendString:@" and "];
        }
        [ret appendString:displayName];
    }

    return ret;
}

- (void)rebuildData {
    NSMutableArray<id> *newData = [NSMutableArray arrayWithArray:[self.messages array]];
    NSArray *consumptionKeys = [[[self seenBy] allKeys] sortedArrayUsingSelector:@selector(compare:)];

    if (newData.count > 0) {
        if (self.userConsumedIndex) {
            TWMMessage *consumptionMessage = [[[self channel] messages] messageForConsumptionIndex:self.userConsumedIndex];
            if (consumptionMessage) {
                NSUInteger ndx = [newData indexOfObject:consumptionMessage];
                if (ndx != (newData.count - 1)) {
                    [newData insertObject:@{
                                            kChannelDataType: kChannelDataTypeUserConsumption
                                            }
                                  atIndex:ndx+1];
                }
            }
        }
        
        for (NSNumber *consumptionIndex in consumptionKeys) {
            TWMMessage *consumptionMessage = [[[self channel] messages] messageForConsumptionIndex:consumptionIndex];
            if (consumptionMessage) {
                NSUInteger ndx = [newData indexOfObject:consumptionMessage];
                [newData insertObject:@{
                                        kChannelDataType: kChannelDataTypeMemberConsumption,
                                        kChannelDataData: self.seenBy[consumptionIndex]
                                        }
                              atIndex:ndx+1];
            }
        }
    }
    
    self.channelData = newData;
    [self.tableView reloadData];
}

- (NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)row {
    NSDictionary<NSString *, id> *ret = nil;
    
    if (row == [self channelData].count) {
        return @{
                 kChannelDataType: kChannelDataTypeMembersTyping
                 };
    }
    
    id data = self.channelData[row];
    if ([data isKindOfClass:[NSDictionary class]]) {
        ret = data;
    } else if ([data isKindOfClass:[TWMMessage class]]) {
        ret = @{
                kChannelDataType: kChannelDataTypeMessage,
                kChannelDataData: data
                };
    }

    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    NSDictionary<NSString *, id> *data = [self dataForRow:indexPath.row];
    if ([data[kChannelDataType] isEqualToString:kChannelDataTypeMembersTyping]) {
        NSString *message = [self typingUsersString];
        MemberTypingTableViewCell *typingCell = [tableView dequeueReusableCellWithIdentifier:@"typing"];
        
        typingCell.typingLabel.text = message;
        [typingCell layoutIfNeeded];
        
        cell = typingCell;
    } else if ([data[kChannelDataType] isEqualToString:kChannelDataTypeUserConsumption]) {
        UITableViewCell *newestCell = [tableView dequeueReusableCellWithIdentifier:@"newest"];

        cell = newestCell;
    } else if ([data[kChannelDataType] isEqualToString:kChannelDataTypeMemberConsumption]) {
        SeenByTableViewCell *consumptionCell = [tableView dequeueReusableCellWithIdentifier:@"consumption"];
        consumptionCell.seenByLabel.text = [NSString stringWithFormat:@"Seen by %@", [self pluralizeListOfMembers:data[kChannelDataData]]];

        cell = consumptionCell;
    } else if ([data[kChannelDataType] isEqualToString:kChannelDataTypeMessage]) {
        MessageTableViewCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"message"];
        TWMMessage *message = data[kChannelDataData];

        messageCell.channel = self.channel;
        messageCell.message = message;
        messageCell.delegate = self;
        
        [self.channel.messages advanceLastConsumedMessageIndex:message.index];
        [messageCell layoutIfNeeded];
        
        cell = messageCell;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    self.cachedHeights[indexPath] = @(cell.frame.size.height);
}

- (void)tableView:(UITableView *)tableView
didEndDisplayingCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.cachedHeights removeObjectForKey:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = tableView.estimatedRowHeight;
    NSNumber *cachedHeight = self.cachedHeights[indexPath];
    if (cachedHeight) {
        height = [cachedHeight floatValue];
    }
    
    return height;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.channel typing];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        [self.view endEditing:YES];
    } else {
        TWMMessage *message = [self.channel.messages createMessageWithBody:textField.text];
        textField.text = @"";
        [self.channel.messages sendMessage:message
                                completion:^(TWMResult *result) {
                                    if (!result.isSuccessful) {
                                        [DemoHelpers displayToastWithMessage:@"Failed to send message." inView:self.view];
                                        NSLog(@"%s: %@", __FUNCTION__, result.error);
                                    }
                                }];
    }
    return YES;
}

#pragma mark - Internal methods

- (void)changeFriendlyName {
    NSString *title = @"Friendly Name";
    NSString *placeholder = @"Friendly Name";
    NSString *initialValue = [self.channel friendlyName];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        [self.channel setFriendlyName:newValue
                           completion:^(TWMResult *result) {
                               if (result.isSuccessful) {
                                   [DemoHelpers displayToastWithMessage:@"Friendly name changed."
                                                                 inView:weakSelf.view];
                               } else {
                                   [DemoHelpers displayToastWithMessage:@"Friendly name could not be changed."
                                                                 inView:weakSelf.view];
                                   NSLog(@"%s: %@", __FUNCTION__, result.error);
                               }
                           }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeMyFriendlyName {
    TwilioIPMessagingClient *client = [[IPMessagingManager sharedManager] client];
    NSString *title = @"My Friendly Name";
    NSString *placeholder = @"Friendly Name";
    NSString *initialValue = [[client userInfo] friendlyName];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        [[client userInfo] setFriendlyName:newValue
                                completion:^(TWMResult *result) {
                                    if (result.isSuccessful) {
                                        [DemoHelpers displayToastWithMessage:@"My friendly name changed."
                                                                      inView:weakSelf.view];
                                    } else {
                                        [DemoHelpers displayToastWithMessage:@"My friendly name could not be changed."
                                                                      inView:weakSelf.view];
                                        NSLog(@"%s: %@", __FUNCTION__, result.error);
                                    }
                                }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeAvatarEmail {
    TwilioIPMessagingClient *client = [[IPMessagingManager sharedManager] client];
    NSMutableDictionary<NSString *, id> *attributes = [[[client userInfo] attributes] mutableCopy];
    NSString *title = @"Avatar Email Address";
    NSString *placeholder = @"Email Address";
    NSString *initialValue = attributes[@"email"];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        attributes[@"email"] = newValue;
        [[client userInfo] setAttributes:attributes
                              completion:^(TWMResult *result) {
                                  if (result.isSuccessful) {
                                      [DemoHelpers displayToastWithMessage:@"Avatar email changed."
                                                                    inView:weakSelf.view];
                                  } else {
                                      [DemoHelpers displayToastWithMessage:@"Avatar email could not be changed."
                                                                    inView:weakSelf.view];
                                      NSLog(@"%s: %@", __FUNCTION__, result.error);
                                  }
                              }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeTopic {
    NSString *title = @"Topic";
    NSString *placeholder = @"Topic";
    NSString *initialValue = [[self.channel attributes] objectForKey:@"topic"];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        NSMutableDictionary *attributes = [self.channel.attributes mutableCopy];
        if (!attributes) {
            attributes = [NSMutableDictionary dictionary];
        }
        attributes[@"topic"] = newValue;
        [self.channel setAttributes:attributes
                         completion:^(TWMResult *result) {
                             if (result.isSuccessful) {
                                 [DemoHelpers displayToastWithMessage:@"Topic changed."
                                                               inView:weakSelf.view];
                             } else {
                                 [DemoHelpers displayToastWithMessage:@"Topic could not be changed."
                                                               inView:weakSelf.view];
                                 NSLog(@"%s: %@", __FUNCTION__, result.error);
                             }
                         }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeUniqueName {
    NSString *title = @"Unique Name";
    NSString *placeholder = @"Unique Name";
    NSString *initialValue = [self.channel uniqueName];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        [self.channel setUniqueName:newValue
                         completion:^(TWMResult *result) {
                             if (result.isSuccessful) {
                                 [DemoHelpers displayToastWithMessage:@"Unique Name changed."
                                                               inView:weakSelf.view];
                             } else {
                                 [DemoHelpers displayToastWithMessage:@"Unique Name could not be changed to the specified value."
                                                               inView:weakSelf.view];
                                 NSLog(@"%s: %@", __FUNCTION__, result.error);
                             }
                         }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeMessage:(TWMMessage *)message {
    NSString *title = @"Message";
    NSString *placeholder = @"Message";
    NSString *initialValue = [message body];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        [message updateBody:newValue
                 completion:^(TWMResult *result) {
                     if (result.isSuccessful) {
                         [DemoHelpers displayToastWithMessage:@"Body changed."
                                                       inView:weakSelf.view];
                     } else {
                         [DemoHelpers displayToastWithMessage:@"Body could not be updated."
                                                       inView:weakSelf.view];
                         NSLog(@"%s: %@", __FUNCTION__, result.error);
                     }
                 }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)addReactionToMessage:(TWMMessage *)message {
    UIAlertController *actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    void (^addReaction)(NSString *) = ^(NSString *emojiString) {
        [DemoHelpers reactionIncrement:emojiString
                               message:message
                                  user:[[[IPMessagingManager sharedManager] client] userInfo].identity];
    };
    
    NSDictionary *emoji = [ReactionView emojis];
    for (NSString *emojiString in [emoji allKeys]) {
        NSString *name = [ReactionView friendlyNameForEmoji:emojiString];
        NSString *label = [NSString stringWithFormat:@"%@ - %@", emoji[emojiString], name];
        [actionsSheet addAction:[UIAlertAction actionWithTitle:label
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           addReaction(emojiString);
                                                       }]];
    }
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil]];
    
    [self presentViewController:actionsSheet
                       animated:YES
                     completion:nil];
}

- (void)inviteMember {
    NSString *title = @"Invite";
    NSString *placeholder = @"User To Invite";
    NSString *initialValue = @"";
    NSString *actionTitle = @"Invite";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        if (!newValue || newValue.length == 0) {
            return;
        }
        
        [self.channel.members inviteByIdentity:newValue
                                    completion:^(TWMResult *result) {
                                        if (result.isSuccessful) {
                                            [DemoHelpers displayToastWithMessage:@"User invited."
                                                                          inView:weakSelf.view];
                                        } else {
                                            [DemoHelpers displayToastWithMessage:@"User could not be invited."
                                                                          inView:weakSelf.view];
                                            NSLog(@"%s: %@", __FUNCTION__, result.error);
                                        }
                                    }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)addMember {
    NSString *title = @"Add";
    NSString *placeholder = @"User To Add";
    NSString *initialValue = @"";
    NSString *actionTitle = @"Add";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        if (!newValue || newValue.length == 0) {
            return;
        }
        
        [self.channel.members addByIdentity:newValue
                                 completion:^(TWMResult *result) {
                                     if (result.isSuccessful) {
                                         [DemoHelpers displayToastWithMessage:@"User added."
                                                                       inView:weakSelf.view];
                                     } else {
                                         [DemoHelpers displayToastWithMessage:@"User could not be added."
                                                                       inView:weakSelf.view];
                                         NSLog(@"%s: %@", __FUNCTION__, result.error);
                                     }
                                 }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)listMembers {
    [self displayUsersList:self.channel.members.allObjects caption:@"Channel Members"];
}

- (void)leaveChannel {
    [self.channel leaveWithCompletion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
        } else {
            [DemoHelpers displayToastWithMessage:@"Failed to leave channel." inView:self.view];
            NSLog(@"%s: %@", __FUNCTION__, result.error);
        }
    }];
}

- (void)destroyMessage:(TWMMessage *)message {
    [self.channel.messages removeMessage:message completion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [self rebuildData];
        } else {
            [DemoHelpers displayToastWithMessage:@"Failed to remove message." inView:self.view];
        }
    }];
}

- (void)promptUserWithTitle:(NSString *)title
                placeholder:(NSString *)placeholder
               initialValue:(NSString *)initialValue
                actionTitle:(NSString *)actionTitle
                     action:(void (^)(NSString *))action {
    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:title
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [dialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = placeholder;
        textField.text = initialValue ? : @"";
    }];
    
    [dialog addAction:[UIAlertAction actionWithTitle:actionTitle
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *alertAction) {
                                                 UITextField *textField = dialog.textFields[0];
                                                 NSString *newValue = textField.text;
                                                 
                                                 action(newValue);
                                             }]];
    
    [dialog addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
    
    [self presentViewController:dialog
                       animated:YES
                     completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGFloat keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    self.keyboardAdjustmentConstraint.constant = keyboardHeight;
    [self.view setNeedsLayout];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    [self scrollToBottomMessage];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardAdjustmentConstraint.constant = 0;
    [self.view setNeedsLayout];
}

- (void)loadMessages {
    [self.messages removeAllObjects];
    [self addMessages:self.channel.messages.allObjects];
}

- (void)addMessages:(NSArray<TWMMessage *> *)messages {
    [self.messages addObjectsFromArray:messages];
    [self sortMessages];
    [self rebuildData];
    if ([self isNearBottom]) {
        [self scrollToLastConsumedMessage];
    }
}

- (BOOL)isNearBottom {
    [self.tableView visibleCells]; // work-around for indexPathsForVisibleRows not being implicitly up to date
    NSArray<NSIndexPath *> *visiblePaths = self.tableView.indexPathsForVisibleRows;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.channelData.count - 2) inSection:0];
    BOOL nearBottom = [visiblePaths containsObject:indexPath];
    return nearBottom;
}

- (void)removeMessages:(NSArray<TWMMessage *> *)messages {
    [self.messages removeObjectsInArray:messages];
    [self sortMessages];
    [self rebuildData];
}

- (void)scrollToLastConsumedMessage {
    if (!self.tableView.dataSource) { // tableview is not yet initialized
        return;
    }
    if (self.messages.count == 0) {
        return;
    }
    
    NSNumber *lastConsumedMessage = [[[self channel] messages] lastConsumedMessageIndex];
    NSUInteger targetIndex = 0;
    if (!lastConsumedMessage) {
        targetIndex = self.channelData.count - 1;
    } else {
        TWMMessage *message = [[[self channel] messages] messageForConsumptionIndex:lastConsumedMessage];
        targetIndex = [[self channelData] indexOfObject:message];
    }

    [self scrollToIndex:targetIndex position:UITableViewScrollPositionTop];
}

- (void)scrollToBottomMessage {
    NSInteger messagesCount = [self channelData].count;
    if (messagesCount == 0) {
        return;
    }
    if (!self.tableView.dataSource) { // tableview is not yet initialized
        return;
    }
    if (self.typingUsers.count > 0) {
        messagesCount++;
    }
    
    [self scrollToIndex:messagesCount - 1 position:UITableViewScrollPositionBottom];
}

- (void)scrollToIndex:(NSUInteger)targetIndex position:(UITableViewScrollPosition)position {
    if (!self.tableView.dataSource) { // tableview is not yet initialized
        return;
    }
    if ([self channelData].count == 0) {
        return;
    }
    
    NSIndexPath *bottomMessageIndex = [NSIndexPath indexPathForRow:(targetIndex)
                                                         inSection:0];
    [self.tableView scrollToRowAtIndexPath:bottomMessageIndex
                          atScrollPosition:position
                                  animated:NO];
}

- (void)sortMessages {
    [self.messages sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                      ascending:YES]]];
}

- (TWMMessage *)messageForIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *data = [self dataForRow:indexPath.row];
    if ([data[kChannelDataType] isEqualToString:kChannelDataTypeMessage]) {
        return data[kChannelDataData];
    }
    return nil;
}

- (BOOL)isMe:(TWMMember *)member {
    return ([member userInfo] == [[[IPMessagingManager sharedManager] client] userInfo]);
}

- (void)displayUsersList:(NSArray *)users caption:(NSString *)caption {
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"usersList"];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    navigationController.preferredContentSize = CGSizeMake(
                                                           self.tableView.frame.size.width * 0.9,
                                                           self.tableView.frame.size.height * 0.5
                                                           );

    UIPopoverPresentationController *popoverController = navigationController.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.sourceView = self.view;
    popoverController.sourceRect = (CGRect){
        .origin = self.tableView.center,
        .size = CGSizeZero
    };
    popoverController.permittedArrowDirections = 0;
    navigationController.navigationBarHidden = YES;

    UserListViewController *userListController = (UserListViewController *)navigationController.topViewController;
    userListController.users = users;
    userListController.caption = caption;
    [self presentViewController:navigationController
                       animated:YES
                     completion:^{
                         
                     }];
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

#pragma mark - TMChannelDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelChanged:(TWMChannel *)channel {
    [self rebuildData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelDeleted:(TWMChannel *)channel {
    if (channel == self.channel) {
        [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
    }
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     channelHistoryLoaded:(TWMChannel *)channel {
    [self loadMessages];
    [self rebuildData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
             memberJoined:(TWMMember *)member {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ joined the channel.", [DemoHelpers displayNameForMember:member]]
                                  inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
            memberChanged:(TWMMember *)member {
    [self refreshSeenBy];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
                   member:(TWMMember *)member
                 userInfo:(TWMUserInfo *)userInfo
                  updated:(TWMUserInfoUpdate)updated {
    if (updated == TWMUserInfoUpdateFriendlyName) {
        [self rebuildData];
    } else if (updated == TWMUserInfoUpdateAttributes ||
               updated == TWMUserInfoUpdateReachabilityOnline ||
               updated == TWMUserInfoUpdateReachabilityNotifiable) {
        NSMutableArray *pathsToUpdate = [NSMutableArray array];
        for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
            if ([[self messageForIndexPath:indexPath].author isEqualToString:member.userInfo.identity]) {
                [pathsToUpdate addObject:indexPath];
            }
        }
        [self.tableView reloadRowsAtIndexPaths:pathsToUpdate
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
               memberLeft:(TWMMember *)member {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ left the channel.", [DemoHelpers displayNameForMember:member]]
                                  inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
             messageAdded:(TWMMessage *)message {
    [self addMessages:@[message]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
           messageDeleted:(TWMMessage *)message {
    [self removeMessages:@[message]];
    [self refreshSeenBy];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
           messageChanged:(TWMMessage *)message {
    [self rebuildData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
   typingStartedOnChannel:(TWMChannel *)channel
                   member:(TWMMember *)member {
    [self.typingUsers addObject:member];
    [self rebuildData];
    if ([self isNearBottom]) {
        [self scrollToBottomMessage];
    }
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     typingEndedOnChannel:(TWMChannel *)channel
                   member:(TWMMember *)member {
    [self.typingUsers removeObject:member];
    [self rebuildData];
    if ([self isNearBottom]) {
        [self scrollToBottomMessage];
    }
}

#pragma mark - MessageTableViewCellDelegate

- (void)reactionIncremented:(NSString *)emojiString
                    message:(TWMMessage *)message {
    [DemoHelpers reactionIncrement:emojiString
                           message:message
                              user:self.localIdentity];
}

- (void)reactionDecremented:(NSString *)emojiString
                    message:(TWMMessage *)message {
    [DemoHelpers reactionDecrement:emojiString
                           message:message
                              user:self.localIdentity];
}

- (void)showUsersForReaction:(NSString *)emojiString
                     message:(TWMMessage *)message {
    NSDictionary *attributes = message.attributes;
    if (!attributes) {
        return;
    }
    
    NSArray *reactions = attributes[@"reactions"];
    if (!reactions) {
        return;
    }
    
    NSDictionary *reaction = nil;
    for (NSDictionary *reactionCandidate in reactions) {
        if ([reactionCandidate[@"reaction"] isEqualToString:emojiString]) {
            reaction = reactionCandidate;
            break;
        }
    }
    if (!reaction) {
        return;
    }

    NSArray *users = [self membersListFromIdentities:reaction[@"users"]];
    NSString *caption = [NSString stringWithFormat:@"%@ Reactions", [ReactionView emojis][emojiString]];
    [self displayUsersList:users caption:caption];
}

- (NSArray *)membersListFromIdentities:(NSArray *)identities {
    NSMutableArray *ret = [NSMutableArray array];
    for (NSString *identity in identities) {
        TWMMember *member = [self.channel memberWithIdentity:identity];
        if (member) {
            [ret addObject:member];
        } else {
            [ret addObject:identity];
        }
    }
    return ret;
}

- (NSString *)localIdentity {
    TWMUserInfo *localUserInfo = [[[IPMessagingManager sharedManager] client] userInfo];
    return localUserInfo.identity;
}

@end
