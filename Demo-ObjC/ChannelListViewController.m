//
//  ChannelListViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "ChannelListViewController.h"
#import "ChannelTableViewCell.h"
#import "ChannelViewController.h"
#import "PushManager.h"

#import <TwilioIPMessagingClient/TwilioIPMessagingClient.h>

@interface ChannelListViewController () <TwilioIPMessagingClientDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) TwilioIPMessagingClient *client;
@property (nonatomic, strong) TMChannels *channelsList;
@property (nonatomic, strong) NSMutableOrderedSet *channels;
@end

@implementation ChannelListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.0f;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self
                            action:@selector(refreshChannels)
                  forControlEvents:UIControlEventValueChanged];

#error - Use the capability string generated in the Twilio SDK portal to populate the token variable and delete this line to build the Demo.
    NSString *token = @"";
    self.client = [TwilioIPMessagingClient ipMessagingClientWithToken:token
                                                             delegate:self];
    
    [PushManager sharedManager].ipMessagingClient = self.client;
    
    [self populateChannels];
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
                                     [self.channelsList createChannelWithFriendlyName:newChannelNameTextField.text
                                                                                 type:isPrivate ? TMChannelTypePrivate : TMChannelTypePublic
                                                                           completion:^(TMResultEnum result, TMChannel *channel) {
                                                                               if (result == TMResultSuccess) {
                                                                                   // TODO: toast user channel creation message
                                                                                   [channel joinWithCompletion:^(TMResultEnum result) {
                                                                                       [channel setAttributes:@{@"topic": @""
                                                                                                                }
                                                                                                   completion:^(TMResultEnum result) {

                                                                                                   }];
                                                                                   }];
                                                                               } else {
                                                                                   // TODO: toast user channel creation failure message
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

- (void)refreshChannels {
    [self populateChannels];

    [self.refreshControl endRefreshing];
}

#pragma mark - Demo helpers

- (void)populateChannels {
    self.channelsList = nil;
    self.channels = nil;
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.client channelsListWithCompletion:^(TMResultEnum result, TMChannels *channelsList) {
            if (result == TMResultSuccess) {
                self.channelsList = channelsList;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self.channelsList loadChannelsWithCompletion:^(TMResultEnum result) {
                        if (result == TMResultSuccess) {
                            self.channels = [[NSMutableOrderedSet alloc] init];
                            [self.channels addObjectsFromArray:[self.channelsList allObjects]];
                            [self sortChannels];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView reloadData];
                            });
                        } else {
                            // TODO: let user know channel load failed to start
                        }
                    }];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPM Demo" message:@"Failed to load channels." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    self.channelsList = nil;
                    [self.channels removeAllObjects];
                    
                    [self.tableView reloadData];
                });
            }
        }];
    });
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
        
        TMChannel *channel = self.channels[indexPath.row];

        NSString *nameLabel = channel.friendlyName;
        if (channel.friendlyName.length == 0) {
            nameLabel = @"(no friendly name)";
        }
        if (channel.type == TMChannelTypePrivate) {
            nameLabel = [nameLabel stringByAppendingString:@" (private)"];
        }
        
        channelCell.nameLabel.text = nameLabel;
        channelCell.sidLabel.text = channel.sid;

        UIColor *channelColor = nil;
        switch (channel.status) {
            case TMChannelStatusInvited:
                channelColor = [UIColor blueColor];
                break;
            case TMChannelStatusJoined:
                channelColor = [UIColor greenColor];
                break;
            case TMChannelStatusNotParticipating:
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Are we just showing loading?
    if (!self.channels) {
        return;
    }
    
    TMChannel *channel = self.channels[indexPath.row];
    
    if (channel.status == TMChannelStatusJoined) {
        [self performSegueWithIdentifier:@"viewChannel" sender:channel];
    } else {
        UIAlertController *channelActions = [UIAlertController alertControllerWithTitle:@"Channel"
                                                                                message:nil
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Join"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [channel joinWithCompletion:^(TMResultEnum result) {
                                                                 // TODO: toast user completion message
                                                                 [self.tableView reloadData];
                                                             }];
                                                         }]];
        
        if (channel.status == TMChannelStatusInvited) {
            [channelActions addAction:[UIAlertAction actionWithTitle:@"Decline Invite"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [channel declineInvitationWithCompletion:^(TMResultEnum result) {
                                                                     // TODO: toast user completion message
                                                                     [self.tableView reloadData];
                                                                 }];
                                                             }]];
        }
        
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Destroy"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [channel destroyWithCompletion:^(TMResultEnum result) {
                                                                 // TODO: toast user completion message
                                                                 [self.tableView reloadData];
                                                             }];
                                                         }]];
        
        [channelActions addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
        
        [self presentViewController:channelActions
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - Internal methods

- (void)sortChannels {
    [self.channels sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"friendlyName"
                                                                      ascending:YES
                                                                       selector:@selector(localizedCaseInsensitiveCompare:)]]];
}

#pragma mark - TwilioIPMessagingClientDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelAdded:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.channels addObject:channel];
        [self sortChannels];
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelChanged:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelDeleted:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.channels removeObject:channel];
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client errorReceived:(TMError *)error {
    // TODO: bring error to users attention
    NSLog(@"error received: %@", error);
}

- (void)ipMessagingClientToastSubscribed:(TwilioIPMessagingClient *)client {

}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client toastReceivedOnChannel:(TMChannel *)channel message:(TMMessage *)message {
    // TODO: bring new message to user's attention
    NSLog(@"toast received: %@ / %@", channel, message);
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client toastRegistrationFailedWithError:(TMError *)error {
    // TODO: bring registration for pushes to users attention?
}

@end
