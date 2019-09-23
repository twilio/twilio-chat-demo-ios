//
//  PublicChannelListViewController.m
//  Twilio Chat Demo
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import "PublicChannelListViewController.h"

#import "DemoHelpers.h"

@interface PublicChannelListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<TCHChannelDescriptor *> *publicChannelDescriptors;
@property (nonatomic, assign, getter=isLoadingMore) BOOL loadingMore;
@end

@implementation PublicChannelListViewController

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
    self.publicChannelDescriptors = [NSMutableArray array];
    self.loadingMore = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setPaginator:(TCHChannelDescriptorPaginator *)paginator {
    if (!self.paginator) { // Seed channel descriptors on first load
        [self.publicChannelDescriptors addObjectsFromArray:paginator.items];
        [self.tableView reloadData];
    }

    _paginator = paginator;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.publicChannelDescriptors.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Public Channels";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (@available(iOS 13.0, *)) {
        [cell setBackgroundColor:UIColor.systemBackgroundColor];
    } else {
        [cell setBackgroundColor:UIColor.whiteColor];
    }
    
    TCHChannelDescriptor *descriptor = self.publicChannelDescriptors[indexPath.row];
    
    NSString *nameLabel = descriptor.friendlyName;
    if (descriptor.friendlyName.length == 0) {
        nameLabel = @"(no friendly name)";
    }

    cell.textLabel.text = [NSString stringWithFormat:@"%@", nameLabel];
    cell.detailTextLabel.text = descriptor.sid;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (self.publicChannelDescriptors.count - 1)) {
        [self loadMoreResults];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:NO
                             completion:^{
                                 TCHChannelDescriptor *descriptor = self.publicChannelDescriptors[indexPath.row];
                                 [descriptor channelWithCompletion:^(TCHResult *result, TCHChannel *channel) {
                                     [channel joinWithCompletion:^(TCHResult *result) {
                                         if (result.isSuccessful) {
                                             [DemoHelpers displayToastWithMessage:@"Channel joined."
                                                                           inView:self.view];
                                         } else {
                                             [DemoHelpers displayToastWithMessage:@"Channel join failed."
                                                                           inView:self.view];
                                             NSLog(@"%s: %@", __FUNCTION__, result.error);
                                         }
                                     }];
                                 }];
                             }];
}

#pragma mark - Helpers

- (void)loadMoreResults {
    @synchronized (self) {
        if (self.paginator && [self.paginator hasNextPage] && !self.isLoadingMore) {
            self.loadingMore = YES;
            
            [self.paginator requestNextPageWithCompletion:^(TCHResult *result, TCHChannelDescriptorPaginator *paginator) {
                if ([result isSuccessful]) {
                    self.paginator = paginator;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSUInteger currentCount = self.publicChannelDescriptors.count;
                        [self.tableView beginUpdates];
                        [self.publicChannelDescriptors addObjectsFromArray:paginator.items];
                        NSUInteger newRowCount = paginator.items.count;
                        NSMutableArray<NSIndexPath *> *newRows = [NSMutableArray arrayWithCapacity:newRowCount];
                        for (int ndx=0; ndx<newRowCount; ndx++) {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentCount+ndx inSection:0];
                            [newRows addObject:indexPath];
                        }
                        [self.tableView insertRowsAtIndexPaths:newRows
                                              withRowAnimation:UITableViewRowAnimationBottom];
                        [self.tableView endUpdates];
                        self.loadingMore = NO;
                    });
                } else {
                    [DemoHelpers displayToastWithMessage:@"Failed to get next page of channels."
                                                  inView:self.view];
                    NSLog(@"%s: %@", __FUNCTION__, result.error);
                    
                    self.loadingMore = NO;
                }
            }];
        }
    }
}

@end
