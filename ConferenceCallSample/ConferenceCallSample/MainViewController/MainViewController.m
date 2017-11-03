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
    
    self.buttonJoinRoom.layer.cornerRadius = 5;
    self.buttonJoinRoom.clipsToBounds = YES;
    self.buttonMakeRoom.layer.cornerRadius = 5;
    self.buttonMakeRoom.clipsToBounds = YES;
    
    [InstanceManager instance].mainViewController = self;
    
    [[StringeeImplement instance] connectToStringeeServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)makeRoomTapped:(UIButton *)sender {
    if ([StringeeImplement instance].stringeeClient.hasConnected) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isMakeRoom = YES;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    }
}

- (IBAction)joinRoomTapped:(UIButton *)sender {
    
    if (!self.tfRoomId.text.length) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Thông báo" message:@"RoomId là rỗng" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertVC addAction:okAction];
        [self presentViewController:alertVC animated:YES completion:nil];
        
        return;
    }
    
    if ([StringeeImplement instance].stringeeClient.hasConnected) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isMakeRoom = NO;
        callingVC.roomId = self.tfRoomId.text.longLongValue;
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    }
}




@end
