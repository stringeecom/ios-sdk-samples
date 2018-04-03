//
//  SPContactTableViewCell.m
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "ContactTableViewCell.h"
#import "AvatarControl.h"
#import "Utils.h"
#import "CallingViewController.h"
#import "StringeeImplement.h"
#import "SPManager.h"
#import "Constants.h"

@implementation ContactTableViewCell {
    ContactModel *contactOfCell;
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

- (void)configureCellWithContact:(ContactModel *)contact {
    
    contactOfCell = contact;
    NSString *name;
    if (contact.name.length) {
        name = contact.name;
    } else {
        name = contact.phone_display;
    }
    
    self.labeName.text = name;
    self.labelPhone.text = contact.phone_display;
    
    NSString *strAvatar = [Utils getStrLetterWithName:name];
    self.imageAvatar.image = [[AvatarControl instance] getAvatar:strAvatar];

    if (contact.isExistence) {
        self.imageLogo.hidden = NO;
        self.btVideoCall.hidden = NO;
    } else {
        self.imageLogo.hidden = YES;
        self.btVideoCall.hidden = YES;
    }
}

- (IBAction)voiceCallTapped:(UIButton *)sender {
    NSLog(@"voiceCallTapped");
    UIAlertControllerStyle style;
    
    if (IS_IPHONE) {
        // iphone
        style = UIAlertControllerStyleActionSheet;
    } else {
        // ipad + tv...
        style = UIAlertControllerStyleAlert;
    }
    
    UIAlertController *confirmAlert = [UIAlertController
                                       alertControllerWithTitle:nil
                                       message:nil
                                       preferredStyle:style];
    
    
    UIAlertAction *callAppToAppAction = [UIAlertAction actionWithTitle:@"Gọi qua Softphone" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self makeCallWithCallContact:contactOfCell isAppToApp:YES isVideoCall:NO];
    }];
    
    UIAlertAction *callAppToPhoneAction = [UIAlertAction actionWithTitle:@"Gọi ra số di động" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self makeCallWithCallContact:contactOfCell isAppToApp:NO isVideoCall:NO];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil];
    [confirmAlert addAction:callAppToAppAction];
    [confirmAlert addAction:callAppToPhoneAction];
    [confirmAlert addAction:cancelAction];
    
    [[SPManager instance].contactViewController.navigationController presentViewController:confirmAlert animated:YES completion:nil];
}

- (IBAction)videoCallTapped:(UIButton *)sender {
    NSLog(@"videoCallTapped");
    [self makeCallWithCallContact:contactOfCell isAppToApp:YES isVideoCall:YES];
}

- (void)makeCallWithCallContact:(ContactModel *)contact isAppToApp:(BOOL)isAppToApp isVideoCall:(BOOL)isVideoCall {
    if ([StringeeImplement instance].stringeeClient.hasConnected && ![[SPManager instance] isSystemCall]) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isIncomingCall = NO;
        
        if (contact.name.length) {
            callingVC.username = contact.name;
        } else {
            callingVC.username = contact.phone_display;
        }
        callingVC.from = [[SPManager instance] getNumberForCallOut];
        callingVC.to = contact.phone_call;
        callingVC.isAppToApp = isAppToApp;
        callingVC.isVideoCall = isVideoCall;
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    } else {
        [Utils showToastWithString:@"Không có kết nối" withView:[[SPManager instance].contactViewController view]];
    }
}


@end
