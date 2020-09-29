//
//  UserListViewController.m
//  Demo-ObjC
//
//  Created by Randy Beiter on 6/28/16.
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <TwilioConversationsClient/TCHParticipant.h>

#import "UserListViewController.h"
#import "DemoHelpers.h"
#import "ChatManager.h"

@interface UserListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation UserListViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.caption = @"Users";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(doneTapped:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)doneTapped:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.caption;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (@available(iOS 13.0, *)) {
        [cell setBackgroundColor:[UIColor systemBackgroundColor]];
    } else {
        [cell setBackgroundColor:UIColor.whiteColor];
    }
    
    id user = self.users[indexPath.row];
    
    if ([user isKindOfClass:[TCHParticipant class]]) {
        TCHParticipant *member = user;
        [ChatManager.sharedManager.client subscribedUserWithIdentity:member.identity
                                                          completion:^(TCHResult *result, TCHUser *user) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [DemoHelpers displayNameForUser:user]];
            cell.imageView.image = [DemoHelpers avatarForUser:user size:44.0 scalingFactor:2.0];

            if ([user.identity isEqualToString:[[[[ChatManager sharedManager] client] user] identity]]) {
                [cell setBackgroundColor:UIColor.groupTableViewBackgroundColor];
            }
        }];
    } else {
        NSString *userIdentity = user;
        cell.textLabel.text = [NSString stringWithFormat:@"%@", userIdentity];
        cell.imageView.image = [DemoHelpers avatarForAuthor:userIdentity size:44.0 scalingFactor:2.0];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

@end
