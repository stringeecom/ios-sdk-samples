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
    [InstanceManager instance].homeViewController = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)callTapped:(UIButton *)sender {
    if ([StringeeImplement instance].stringeeClient.hasConnected && self.tfUserId.text.length) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isIncomingCall = NO;
        callingVC.from = [StringeeImplement instance].stringeeClient.userId;
        callingVC.to = self.tfUserId.text;
        [self presentViewController:callingVC animated:YES completion:nil];
    }
}

@end
