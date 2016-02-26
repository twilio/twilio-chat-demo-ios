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

static NSString * const kChannelDataType = @"channelDataType";
static NSString * const kChannelDataTypeMessage = @"message";
static NSString * const kChannelDataTypeMemberConsumption = @"memberConsumption";
static NSString * const kChannelDataTypeUserConsumption = @"userConsumption";
static NSString * const kChannelDataTypeMembersTyping = @"membersTyping";
static NSString * const kChannelDataData = @"channelDataData";

@interface ChannelViewController () <UITableViewDataSource, UITableViewDelegate, TWMChannelDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAdjustmentConstraint;

@property (nonatomic, strong) NSMutableOrderedSet *messages;
@property (nonatomic, strong) NSMutableArray<id> *channelData;
@property (nonatomic, strong) NSMutableArray *typingUsers;
@property (nonatomic, copy) NSNumber *userConsumedIndex;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSArray<TWMMember *> *> *seenBy;
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
    NSString *myIdentity = [[IPMessagingManager sharedManager] identity];
    for (TWMMember *member in [self.channel.members allObjects]) {
        if (![member.identity isEqualToString:myIdentity]) {
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
    // Do any additional setup after loading the view.
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

- (IBAction)performAction:(id)sender {
    UIAlertController *actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak __typeof(self) weakSelf = self;
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Change Friendly Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeFriendlyName];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Change Unique Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeUniqueName];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Change Topic"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf changeTopic];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"List Members"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf listMembers];
                                                   }]];

    if (self.channel.type == TWMChannelTypePrivate) {
        // Invite is only valid for private channels
        [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Invite Member"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [weakSelf inviteMember];
                                                       }]];
    }

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Add Member"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf addMember];
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
    NSArray *membersSorted = [members sortedArrayUsingComparator:^NSComparisonResult(TWMMember *obj1, TWMMember *obj2) {
        return [obj1.identity compare:obj2.identity options:NSCaseInsensitiveSearch];
    }];

    NSMutableString *ret = [NSMutableString string];
    
    for (int ndx=0; ndx < membersSorted.count; ndx++) {
        TWMMember *member = (TWMMember *)membersSorted[ndx];
        if (ndx > 0 && ndx < membersSorted.count - 1) {
            [ret appendString:@", "];
        } else if (ndx > 0 && ndx == membersSorted.count - 1) {
            [ret appendString:@" and "];
        }
        [ret appendString:member.identity];
    }

    return ret;
}

- (void)rebuildData {
    NSMutableArray<id> *newData = [NSMutableArray arrayWithArray:[self.messages array]];
    NSArray *consumptionKeys = [[[self seenBy] allKeys] sortedArrayUsingSelector:@selector(compare:)];

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
        [self.channel.messages advanceLastConsumedMessageIndex:message.index];
        messageCell.authorLabel.text = message.author;
        messageCell.dateLabel.text = message.timestamp;
        messageCell.bodyLabel.text = message.body;
        [messageCell layoutIfNeeded];
        
        cell = messageCell;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray array];
    TWMMessage *message = [self messageForIndexPath:indexPath];
    
    if (!message) {
        return @[];
    }
    
    __weak __typeof(self) weakSelf = self;
    [actions addObject:[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                          title:@"Destroy"
                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                            weakSelf.tableView.editing = NO;
                                                            [self destroyMessage:message];
                                                        }]];
    
    [actions addObject:[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                          title:@"Edit"
                                                        handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                            [self changeMessage:message];
                                                        }]];
    
    return actions;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TWMMessage *message = [self messageForIndexPath:indexPath];
        [self destroyMessage:message];
    }
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
                                completion:^(TWMResult result) {
                                    if (result == TWMResultFailure) {
                                        [DemoHelpers displayToastWithMessage:@"Failed to send message." inView:self.view];
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
        if (!newValue || newValue.length == 0) {
            return;
        }

        [self.channel setFriendlyName:newValue
                           completion:^(TWMResult result) {
                               if (result == TWMResultSuccess) {
                                   [DemoHelpers displayToastWithMessage:@"Friendly name changed."
                                                                 inView:weakSelf.view];
                               } else {
                                   [DemoHelpers displayToastWithMessage:@"Friendly name could not be changed."
                                                                 inView:weakSelf.view];
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
                         completion:^(TWMResult result) {
                             if (result == TWMResultSuccess) {
                                 [DemoHelpers displayToastWithMessage:@"Topic changed."
                                                               inView:weakSelf.view];
                             } else {
                                 [DemoHelpers displayToastWithMessage:@"Topic could not be changed."
                                                               inView:weakSelf.view];
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
                         completion:^(TWMResult result) {
                             if (result == TWMResultSuccess) {
                                 [DemoHelpers displayToastWithMessage:@"Unique Name changed."
                                                               inView:weakSelf.view];
                             } else {
                                 [DemoHelpers displayToastWithMessage:@"Unique Name could not be changed to the specified value."
                                                               inView:weakSelf.view];
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
                 completion:^(TWMResult result) {
                     if (result == TWMResultSuccess) {
                         [DemoHelpers displayToastWithMessage:@"Body changed."
                                                       inView:weakSelf.view];
                     } else {
                         [DemoHelpers displayToastWithMessage:@"Body could not be updated."
                                                       inView:weakSelf.view];
                     }
                 }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
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
                                    completion:^(TWMResult result) {
                                        if (result == TWMResultSuccess) {
                                            [DemoHelpers displayToastWithMessage:@"User invited."
                                                                          inView:weakSelf.view];
                                        } else {
                                            [DemoHelpers displayToastWithMessage:@"User could not be invited."
                                                                          inView:weakSelf.view];
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
                                 completion:^(TWMResult result) {
                                     if (result == TWMResultSuccess) {
                                         [DemoHelpers displayToastWithMessage:@"User added."
                                                                       inView:weakSelf.view];
                                     } else {
                                         [DemoHelpers displayToastWithMessage:@"User could not be added."
                                                                       inView:weakSelf.view];
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
    NSString *membersList = [self pluralizeListOfMembers:self.channel.members.allObjects];
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"Members:\n%@", membersList] inView:self.view];
}

- (void)leaveChannel {
    [self.channel leaveWithCompletion:^(TWMResult result) {
        if (result == TWMResultSuccess) {
            [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
        } else {
            [DemoHelpers displayToastWithMessage:@"Failed to leave channel." inView:self.view];
        }
    }];
}

- (void)destroyMessage:(TWMMessage *)message {
    [self.channel.messages removeMessage:message completion:^(TWMResult result) {
        if (result == TWMResultSuccess) {
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
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ joined the channel.", member.identity]
                                  inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
            memberChanged:(TWMMember *)member {
    [self refreshSeenBy];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TWMChannel *)channel
               memberLeft:(TWMMember *)member {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ left the channel.", member.identity]
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

@end
