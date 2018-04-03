//
//  NumberTableViewCell.h
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalloutNumberModel.h"

@interface NumberTableViewCell : UITableViewCell

// Outlet
@property (weak, nonatomic) IBOutlet UISwitch *swNumber;
@property (weak, nonatomic) IBOutlet UILabel *lbNumber;

- (IBAction)switchTapped:(UISwitch *)sender;

// Declare
@property (assign, nonatomic) BOOL isNumber1;
@property (strong, nonatomic) CalloutNumberModel *calloutNumber;
@property (assign, nonatomic) int calloutNumberIndex;

- (void)configureCellWithCallOutNumber:(CalloutNumberModel *)calloutNumber calloutNumberIndex:(int)calloutNumberIndex;

@end
