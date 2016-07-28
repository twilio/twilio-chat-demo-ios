//
//  ReactionsView.h
//  Demo-ObjC
//
//  Created by Randy Beiter on 6/26/16.
//  Copyright © 2016 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReactionView.h"

IB_DESIGNABLE @interface ReactionsView : UIView

@property (nonatomic, assign) IBOutlet id<ReactionViewDelegate> delegate;
@property (nonatomic, strong) NSArray *reactions;
@property (nonatomic, copy) NSString *localIdentity;

@end
