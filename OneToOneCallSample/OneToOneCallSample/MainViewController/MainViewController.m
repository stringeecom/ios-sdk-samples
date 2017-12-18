//
//  MainViewController.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "MainViewController.h"
#import "InstanceManager.h"
#import "StringeeImplement.h"
#import "CallingViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Connecting...";
    self.buttonCall.layer.cornerRadius = 5;
    self.buttonCall.clipsToBounds = YES;
    [InstanceManager instance].mainViewController = self;
    [[StringeeImplement instance] connectToStringeeServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)callTapped:(UIButton *)sender {
    
    if (!self.tfUserID.text.length) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Notification" message:@"UserID is empty" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertVC addAction:okAction];
        [self presentViewController:alertVC animated:YES completion:nil];
        
        return;
    }
    
    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
    callingVC.username = @"Target User";
    callingVC.from = [StringeeImplement instance].stringeeClient.userId;
    callingVC.to = self.tfUserID.text;
    callingVC.isIncomingCall = NO;
    if (self.switchVideoCall.isOn) {
        callingVC.isVideoCall = YES;
    } else {
        callingVC.isVideoCall = NO;
    }
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];

    

}


@end
