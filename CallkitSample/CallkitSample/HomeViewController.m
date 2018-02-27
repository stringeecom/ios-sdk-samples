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
        UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CallingViewController *callingVC = (CallingViewController *)[mainSB instantiateViewControllerWithIdentifier:@"CallingViewController"];
        callingVC.isOutgoingCall = YES;
        callingVC.strUserId = self.tfUserId.text;
        [self presentViewController:callingVC animated:YES completion:nil];
    }
}

@end
