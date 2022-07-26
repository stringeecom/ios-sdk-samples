//
//  ViewController.m
//  CallkitSample
//
//  Created by Hoang Duoc on 2/1/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "HomeViewController.h"
#import "InstanceManager.h"
#import "StringeeImplement.h"
#import "CallingViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [InstanceManager instance].homeVC = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)voiceCallTapped:(UIButton *)sender {
    if ([StringeeImplement instance].stringeeClient.hasConnected && self.tfUserId.text.length) {
        CallingViewController *callingVC = [[CallingViewController alloc] initFrom:[StringeeImplement instance].stringeeClient.userId to:self.tfUserId.text isVideo:false];
        [self presentViewController:callingVC animated:YES completion:nil];
    }
}

- (IBAction)videoCapTapped:(id)sender {
    if ([StringeeImplement instance].stringeeClient.hasConnected && self.tfUserId.text.length) {
        CallingViewController *callingVC = [[CallingViewController alloc] initFrom:[StringeeImplement instance].stringeeClient.userId to:self.tfUserId.text isVideo:true];
        [self presentViewController:callingVC animated:YES completion:nil];
    }
}

@end
