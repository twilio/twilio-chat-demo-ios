//
//  ChannelViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "ChannelViewController.h"
#import "MessageTableViewCell.h"
#import "MemberTypingTableViewCell.h"
#import "DemoHelpers.h"

@interface ChannelViewController () <UITableViewDataSource, UITableViewDelegate, TMChannelDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableOrderedSet *messages;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAdjustmentConstraint;
@property (nonatomic, strong) NSMutableArray *typingUsers;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.channel) {
        self.channel.delegate = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setChannel:(TMChannel *)channel {
    _channel = channel;
    self.channel.delegate = self;

    [self loadMessages];
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

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Invite Member"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [weakSelf inviteMember];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = self.messages.count;
    if (self.typingUsers.count > 0) {
        count++;
    }
    return count;
}

- (NSString *)typingUsersString {
    NSArray *typingUsers = [self.typingUsers copy];
    
    NSMutableString *ret = [NSMutableString string];

    for (int ndx=0; ndx < typingUsers.count; ndx++) {
        TMMember *member = (TMMember *)typingUsers[ndx];
        if (ndx > 0 && ndx < typingUsers.count - 1) {
            [ret appendString:@", "];
        } else if (ndx > 0 && ndx == typingUsers.count - 1) {
            [ret appendString:@" and "];
        }
        [ret appendString:member.identity];
    }
    
    return [NSString stringWithFormat:@"%@ %@ typing...", ret, typingUsers.count > 1 ? @"are" : @"is"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (self.typingUsers.count > 0 && indexPath.row == self.messages.count) {
        NSString *message = [self typingUsersString];
        MemberTypingTableViewCell *typingCell = [tableView dequeueReusableCellWithIdentifier:@"typing"];

        typingCell.typingLabel.text = message;
        [typingCell layoutIfNeeded];
        
        cell = typingCell;
    } else {
        MessageTableViewCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"message"];
        TMMessage *message = self.messages[indexPath.row];
        
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
    TMMessage *message = [self messageForIndexPath:indexPath];
    
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
        TMMessage *message = [self messageForIndexPath:indexPath];
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
        TMMessage *message = [self.channel.messages createMessageWithBody:textField.text];
        textField.text = @"";
        [self.channel.messages sendMessage:message
                                completion:^(TMResultEnum result) {
                                    if (result == TMResultFailure) {
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
                           completion:^(TMResultEnum result) {
                               if (result == TMResultSuccess) {
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
                         completion:^(TMResultEnum result) {
                             if (result == TMResultSuccess) {
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
                         completion:^(TMResultEnum result) {
                             if (result == TMResultSuccess) {
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

- (void)changeMessage:(TMMessage *)message {
    NSString *title = @"Message";
    NSString *placeholder = @"Message";
    NSString *initialValue = [message body];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        [message updateBody:newValue
                 completion:^(TMResultEnum result) {
                     if (result == TMResultSuccess) {
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
                                    completion:^(TMResultEnum result) {
                                        if (result == TMResultSuccess) {
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

- (void)listMembers {
    NSArray *members = [self.channel.members.allObjects sortedArrayUsingComparator:^NSComparisonResult(TMMember *obj1, TMMember *obj2) {
        return [obj1.identity compare:obj2.identity options:NSCaseInsensitiveSearch];
    }];
    NSMutableString *membersList = [NSMutableString string];
    [members enumerateObjectsUsingBlock:^(TMMember *member, NSUInteger idx, BOOL *stop) {
        [membersList appendFormat:@"%@%@", membersList.length>0?@", ":@"", member.identity];
    }];
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"Members:\n%@", membersList] inView:self.view];
}

- (void)leaveChannel {
    [self.channel leaveWithCompletion:^(TMResultEnum result) {
        if (result == TMResultSuccess) {
            [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
        } else {
            [DemoHelpers displayToastWithMessage:@"Failed to leave channel." inView:self.view];
        }
    }];
}

- (void)destroyMessage:(TMMessage *)message {
    [self.channel.messages removeMessage:message completion:^(TMResultEnum result) {
        if (result == TMResultSuccess) {
            [self.tableView reloadData];
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

- (void)addMessages:(NSArray<TMMessage *> *)messages {
    [self.messages addObjectsFromArray:messages];
    [self sortMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.messages.count > 0) {
            [self scrollToBottomMessage];
        }
    });
}

- (void)removeMessages:(NSArray<TMMessage *> *)messages {
    [self.messages removeObjectsInArray:messages];
    [self sortMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.messages.count > 0) {
            [self scrollToBottomMessage];
        }
    });
}

- (void)scrollToBottomMessage {
    if (self.messages.count == 0) {
        return;
    }
    
    NSIndexPath *bottomMessageIndex = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1
                                                         inSection:0];
    [self.tableView scrollToRowAtIndexPath:bottomMessageIndex
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
}

- (void)sortMessages {
    [self.messages sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                      ascending:YES]]];
}

- (TMMessage *)messageForIndexPath:(nonnull NSIndexPath *)indexPath {
    return self.messages[indexPath.row];
}

#pragma mark - TMChannelDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelChanged:(TMChannel *)channel {
    [DemoHelpers displayToastWithMessage:@"Channel attributes changed."
                                  inView:self.view];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelDeleted:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (channel == self.channel) {
            [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
        }
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     channelHistoryLoaded:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
             memberJoined:(TMMember *)member {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ joined the channel.", member.identity]
                                  inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
            memberChanged:(TMMember *)member {

}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
               memberLeft:(TMMember *)member {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"%@ left the channel.", member.identity]
                                  inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
             messageAdded:(TMMessage *)message {
    [self addMessages:@[message]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
           messageDeleted:(TMMessage *)message {
    [self removeMessages:@[message]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
           messageChanged:(TMMessage *)message {
    [self.tableView reloadData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
   typingStartedOnChannel:(TMChannel *)channel
                   member:(TMMember *)member {
    [self.typingUsers addObject:member];
    [self.tableView reloadData];
    [self scrollToBottomMessage];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     typingEndedOnChannel:(TMChannel *)channel
                   member:(TMMember *)member {
    [self.typingUsers removeObject:member];
    [self.tableView reloadData];
    [self scrollToBottomMessage];
}

@end
