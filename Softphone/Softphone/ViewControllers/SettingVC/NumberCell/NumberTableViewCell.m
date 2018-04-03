//
//  NumberTableViewCell.m
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "NumberTableViewCell.h"
#import "SPManager.h"
#import "Constants.h"

@implementation NumberTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)switchTapped:(UISwitch *)sender {
    CalloutNumberModel *calloutNumberAtIndex = [[SPManager instance].myUser.calloutNumbers objectAtIndex:_calloutNumberIndex];
    if (calloutNumberAtIndex) {
        if ([sender isOn]) {
            calloutNumberAtIndex.isEnable = YES;
        } else {
            calloutNumberAtIndex.isEnable = NO;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_Number" object:nil userInfo:nil];

}

- (void)configureCellWithCallOutNumber:(CalloutNumberModel *)calloutNumber calloutNumberIndex:(int)calloutNumberIndex {
    
    _calloutNumber = calloutNumber;
    _calloutNumberIndex = calloutNumberIndex;
    
    self.lbNumber.text = [@"+" stringByAppendingString:calloutNumber.phone];
    if (calloutNumber.isEnable) {
        [self.swNumber setOn:YES];
    } else {
        [self.swNumber setOn:NO];
    }
}

@end
