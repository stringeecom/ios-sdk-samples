//
//  SPContactTableViewCell.h
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactModel.h"

@interface ContactTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageAvatar;
@property (weak, nonatomic) IBOutlet UILabel *labeName;
@property (weak, nonatomic) IBOutlet UILabel *labelPhone;
@property (weak, nonatomic) IBOutlet UIImageView *imageLogo;
@property (weak, nonatomic) IBOutlet UIButton *btVideoCall;


- (IBAction)voiceCallTapped:(UIButton *)sender;
- (IBAction)videoCallTapped:(UIButton *)sender;


- (void)configureCellWithContact:(ContactModel *)contact;


@end
