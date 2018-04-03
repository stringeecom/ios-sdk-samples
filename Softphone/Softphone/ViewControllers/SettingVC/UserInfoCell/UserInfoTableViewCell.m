//
//  SPUserInfoTableViewCell.m
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "UserInfoTableViewCell.h"
#import "StringeeImplement.h"
#import "AvatarControl.h"
#import "Utils.h"
#import "SPManager.h"
#import "Constants.h"

@implementation UserInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.imageAvatar.backgroundColor = [UIColor grayColor];
    self.imageAvatar.layer.cornerRadius = self.imageAvatar.frame.size.width / 2;
    self.imageAvatar.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureCell {
    
    NSString *username;
    
    if ([StringeeImplement instance].stringeeClient.userId.length) {
        username = [StringeeImplement instance].stringeeClient.userId;
    } else {
        username = @"Connecting...";
    }
    
    self.labelName.text = username;
    
    NSString *strAvatar = [Utils getStrLetterWithName:username];
    self.imageAvatar.image = [[AvatarControl instance] getAvatar:strAvatar];

    NSString *number = [[SPManager instance] getNumberForCallOut];
    if (number.length) {
        self.labelPhone.text = [@"+" stringByAppendingString:number];
    } else {
        self.labelPhone.text = @"Không có số gọi ra";
    }
    
}

@end
