//
//  MessageTableViewCell.h
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *authorLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *bodyLabel;

@end
