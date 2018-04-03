//
//  SPHistoryTableViewCell.m
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "HistoryTableViewCell.h"
#import "AvatarControl.h"
#import "Utils.h"

@implementation HistoryTableViewCell {
    CallHistoryModel *callHistoryModel;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageAvatar.layer.cornerRadius = self.imageAvatar.frame.size.width / 2;
    self.imageAvatar.clipsToBounds = YES;
    
    self.imageLogo.layer.cornerRadius = self.imageLogo.frame.size.width / 2;
    self.imageLogo.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (void)configureCellWithCallHistory:(CallHistoryModel *)callHistory {
    callHistoryModel = callHistory;
    
    NSString *name;
    
    if (callHistory.name.length) {
        name = callHistory.name;
    } else {
        name = callHistory.phone;
    }
    
    self.labelUsername.text = name;
    self.labelDuration.text = callHistory.duration;

    NSString *strAvatar = [Utils getStrLetterWithName:name];
    self.imageAvatar.image = [[AvatarControl instance] getAvatar:strAvatar];
    
    if (callHistory.state == IncomingCall) {
        self.labelStatus.text = @"Cuộc gọi đến";
        [self.imageStatus setImage:[UIImage imageNamed:@"history_incoming_call"]];
    } else if (callHistory.state == OutgoingCall) {
        self.labelStatus.text = @"Cuộc gọi đi";
        [self.imageStatus setImage:[UIImage imageNamed:@"history_call_away"]];
    } else {
        self.labelStatus.text = @"Cuộc gọi nhỡ";
        [self.imageStatus setImage:[UIImage imageNamed:@"history_miss_call"]];
    }
    
    if (callHistory.isAppToApp) {
        self.imageLogo.hidden = NO;
    } else {
        self.imageLogo.hidden = YES;
    }
    
    if ([[Utils getCurrentSystemDate] isEqualToString:callHistory.date]) {
        self.labelTime.text = callHistory.hour;
    } else {
        self.labelTime.text = callHistory.date;
    }

    if (callHistory.isVideoCall) {
        [self.imageCallType setImage:[UIImage imageNamed:@"video_call_icon"]];
    } else {
        [self.imageCallType setImage:[UIImage imageNamed:@"voice_call_icon"]];
    }
    
}

@end
