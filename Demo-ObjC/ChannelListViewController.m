//
//  ChannelListViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "ChannelListViewController.h"
#import "ChannelTableViewCell.h"
#import "ChannelViewController.h"
#import "IPMessagingManager.h"
#import "DemoHelpers.h"

@interface ChannelListViewController () <TwilioIPMessagingClientDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) TWMChannels *channelsList;
@property (nonatomic, strong) NSMutableOrderedSet *channels;
@end

@implementation ChannelListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self
                            action:@selector(refreshChannels)
                  forControlEvents:UIControlEventValueChanged];

    TwilioIPMessagingClient *client = [[IPMessagingManager sharedManager] client];
    if (client) {
        client.delegate = self;
        [self populateChannels];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewChannel"]) {
        ChannelViewController *vc = segue.destinationViewController;
        vc.channel = sender;
    }
}

- (IBAction)returnFromChannel:(UIStoryboardSegue *)segue {
    [self.tableView reloadData];
}

- (IBAction)logoutTapped:(id)sender {
    [[IPMessagingManager sharedManager] logout];
    [[IPMessagingManager sharedManager] presentRootViewController];
}

- (IBAction)newChannelTapped:(id)sender {
    UIAlertController *newChannelActionSheet = [UIAlertController alertControllerWithTitle:@"New Channel"
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    [newChannelActionSheet addAction:[UIAlertAction actionWithTitle:@"Public Channel"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self newChannelPrivate:NO];
                                                            }]];
    
    [newChannelActionSheet addAction:[UIAlertAction actionWithTitle:@"Private Channel"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self newChannelPrivate:YES];
                                                            }]];
    
    [newChannelActionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil]];

    [self presentViewController:newChannelActionSheet
                       animated:YES
                     completion:nil];
}

- (void)newChannelPrivate:(BOOL)isPrivate {
    UIAlertController *newChannelDialog = [UIAlertController alertControllerWithTitle:@"New Channel"
                                                                              message:@"What would you like to call the new channel?"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [newChannelDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Channel Name";
    }];
    
    [newChannelDialog addAction:[UIAlertAction actionWithTitle:@"Create"
                                                         style:UIAlertActionStyleDefault
                                                       handler:
                                 ^(UIAlertAction *action) {
                                     UITextField *newChannelNameTextField = newChannelDialog.textFields[0];

                                     NSMutableDictionary *options = [NSMutableDictionary dictionary];
                                     if (newChannelNameTextField &&
                                         newChannelNameTextField.text &&
                                         ![newChannelNameTextField.text isEqualToString:@""]) {
                                         options[TWMChannelOptionFriendlyName] = newChannelNameTextField.text;
                                     }
                                     if (isPrivate) {
                                         options[TWMChannelOptionType] = @(TWMChannelTypePrivate);
                                     }
                                     
                                     [self.channelsList createChannelWithOptions:options
                                                                      completion:^(TWMResult *result, TWMChannel *channel) {
                                                                          if (result.isSuccessful) {
                                                                              [DemoHelpers displayToastWithMessage:@"Channel Created"
                                                                                                            inView:self.view];
                                                                          } else {
                                                                              [DemoHelpers displayToastWithMessage:@"Channel Create Failed"
                                                                                                            inView:self.view];
                                                                              NSLog(@"%s: %@", __FUNCTION__, result.error);
                                                                          }
                                                                      }];
                                 }]];
    
    [newChannelDialog addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil]];
    
    [self presentViewController:newChannelDialog
                       animated:YES
                     completion:nil];
}

- (void)displayOperationsForChannel:(TWMChannel *)channel
                        calledFromSwipe:(BOOL)calledFromSwipe {
    __weak __typeof(self) weakSelf = self;
    
    UIAlertController *channelActions = [UIAlertController alertControllerWithTitle:@"Channel"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];

    if (channel.status == TWMChannelStatusJoined) {
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Leave"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [weakSelf leaveChannel:channel];
                                                         }]];
    }
    
    if (channel.status == TWMChannelStatusInvited) {
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Decline Invite"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [weakSelf declineInviteOnChannel:channel];
                                                         }]];
    }
    
    if (channel.status == TWMChannelStatusInvited || channel.status == TWMChannelStatusNotParticipating) {
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Join"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [weakSelf joinChannel:channel];
                                                         }]];
    }

    if (!calledFromSwipe) {
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Destroy"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [weakSelf destroyChannel:channel];
                                                         }]];
    }
    
    [channelActions addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil]];
    
    [self presentViewController:channelActions
                       animated:YES
                     completion:nil];
}

- (void)refreshChannels {
    [self populateChannels];

    [self.refreshControl endRefreshing];
}

#pragma mark - Demo helpers

- (void)populateChannels {
    self.channelsList = nil;
    self.channels = nil;
    [self.tableView reloadData];
    
    [[[IPMessagingManager sharedManager] client] channelsListWithCompletion:^(TWMResult *result, TWMChannels *channelsList) {
        self.channels = [[NSMutableOrderedSet alloc] init];
        if (result.isSuccessful) {
            self.channelsList = channelsList;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.channelsList loadChannelsWithCompletion:^(TWMResult *result) {
                    if (result.isSuccessful) {
                        [self.channels addObjectsFromArray:[self.channelsList allObjects]];
                        [self sortChannels];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                        });
                    } else {
                        [DemoHelpers displayToastWithMessage:@"Channel list load failed."
                                                      inView:self.view];
                    }
                }];
            });
        } else {
            NSLog(@"%s: %@", __FUNCTION__, result.error);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IP Messaging Demo"
                                                                           message:@"Failed to load channels."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
            
            self.channelsList = nil;
            [self.channels removeAllObjects];
            
            [self.tableView reloadData];
        }
    }];
}

- (void)leaveChannel:(TWMChannel *)channel {
    [channel leaveWithCompletion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [DemoHelpers displayToastWithMessage:@"Channel left."
                                          inView:self.view];
        } else {
            [DemoHelpers displayToastWithMessage:@"Channel leave failed."
                                          inView:self.view];
            NSLog(@"%s: %@", __FUNCTION__, result.error);
        }
        [self.tableView reloadData];
    }];
}

- (void)destroyChannel:(TWMChannel *)channel {
    [channel destroyWithCompletion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [DemoHelpers displayToastWithMessage:@"Channel destroyed."
                                          inView:self.view];
        } else {
            [DemoHelpers displayToastWithMessage:@"Channel destroy failed."
                                          inView:self.view];
            NSLog(@"%s: %@", __FUNCTION__, result.error);
        }
        [self.tableView reloadData];
    }];
}

- (void)joinChannel:(TWMChannel *)channel {
    [channel joinWithCompletion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [DemoHelpers displayToastWithMessage:@"Channel joined."
                                          inView:self.view];
        } else {
            [DemoHelpers displayToastWithMessage:@"Channel join failed."
                                          inView:self.view];
            NSLog(@"%s: %@", __FUNCTION__, result.error);
        }
        [self.tableView reloadData];
    }];
}

- (void)declineInviteOnChannel:(TWMChannel *)channel {
    [channel declineInvitationWithCompletion:^(TWMResult *result) {
        if (result.isSuccessful) {
            [DemoHelpers displayToastWithMessage:@"Invite declined."
                                          inView:self.view];
        } else {
            [DemoHelpers displayToastWithMessage:@"Invite declined failed."
                                          inView:self.view];
            NSLog(@"%s: %@", __FUNCTION__, result.error);
        }
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.channels) {
        return 1;
    }
    
    return self.channels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (!self.channels) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"loading"];
    } else {
        ChannelTableViewCell *channelCell = [tableView dequeueReusableCellWithIdentifier:@"channel"];
        
        TWMChannel *channel = self.channels[indexPath.row];

        NSString *nameLabel = channel.friendlyName;
        if (channel.friendlyName.length == 0) {
            nameLabel = @"(no friendly name)";
        }
        if (channel.type == TWMChannelTypePrivate) {
            nameLabel = [nameLabel stringByAppendingString:@" (private)"];
        }
        
        channelCell.nameLabel.text = nameLabel;
        channelCell.sidLabel.text = channel.sid;

        UIColor *channelColor = nil;
        switch (channel.status) {
            case TWMChannelStatusInvited:
                channelColor = [UIColor blueColor];
                break;
            case TWMChannelStatusJoined:
                channelColor = [UIColor greenColor];
                break;
            case TWMChannelStatusNotParticipating:
                channelColor = [UIColor grayColor];
                break;
        }
        channelCell.nameLabel.textColor = channelColor;
        channelCell.sidLabel.textColor = channelColor;
        
        cell = channelCell;
    }
    
    [cell layoutIfNeeded];
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (TWMChannel *)channelForIndexPath:(NSIndexPath *)indexPath {
    if (!self.channels || indexPath.row >= self.channels.count) {
        return nil;
    }
    
    return self.channels[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Are we just showing loading?
    if (!self.channels) {
        return;
    }
    
    TWMChannel *channel = [self channelForIndexPath:indexPath];
    
    if (channel.status == TWMChannelStatusJoined) {
        [self performSegueWithIdentifier:@"viewChannel" sender:channel];
    } else {
        [self displayOperationsForChannel:channel
                          calledFromSwipe:NO];
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray array];
    TWMChannel *channel = [self channelForIndexPath:indexPath];

    __weak __typeof(self) weakSelf = self;
    [actions addObject:[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                          title:@"Destroy"
                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                            weakSelf.tableView.editing = NO;
                                                            [self destroyChannel:channel];
    }]];
    
    [actions addObject:[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                          title:@"Actions"
                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                            weakSelf.tableView.editing = NO;
                                                            [self displayOperationsForChannel:channel
                                                                              calledFromSwipe:YES];
                                                        }]];
    
    return actions;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TWMChannel *channel = [self channelForIndexPath:indexPath];
        [self destroyChannel:channel];
    }
}

#pragma mark - Internal methods

- (void)sortChannels {
    [self.channels sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"friendlyName"
                                                                      ascending:YES
                                                                       selector:@selector(localizedCaseInsensitiveCompare:)]]];
}

#pragma mark - TwilioIPMessagingClientDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelAdded:(TWMChannel *)channel {
    [self.channels addObject:channel];
    [self sortChannels];
    [self.tableView reloadData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelChanged:(TWMChannel *)channel {
    [self.tableView reloadData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelDeleted:(TWMChannel *)channel {
    [self.channels removeObject:channel];
    [self.tableView reloadData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client errorReceived:(TWMError *)error {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"Error received: %@", error] inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client toastReceivedOnChannel:(TWMChannel *)channel message:(TWMMessage *)message {
    [DemoHelpers displayToastWithMessage:[NSString stringWithFormat:@"New message on channel '%@'.", channel.friendlyName] inView:self.view];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client toastRegistrationFailedWithError:(TWMError *)error {
    // you can bring failures in registration for pushes to user's attention here
}

@end
