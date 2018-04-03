//
//  ConfirmViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/16/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "ConfirmViewController.h"
#import "GlobalService.h"
#import "Utils.h"
#import "SPManager.h"
#import "UserModel.h"
#import "MainTabBarController.h"

@interface ConfirmViewController ()

@end

@implementation ConfirmViewController {
    BOOL isShowKeyboard;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isShowKeyboard = YES;
    self.title = @"Xác nhận";
    self.tfPinCode.delegate = self;
    self.tfPinCode.keyboardType = UIKeyboardTypeNumberPad;
    self.lbDescription.text = [NSString stringWithFormat:@"Mã kích hoạt đã được gửi đến số %@", self.phoneNumber];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (isShowKeyboard) {
        [self.tfPinCode becomeFirstResponder];
    }
}

- (BOOL)textFieldShouldBeginEditing:(PinCodeTextField *)textField {
    NSLog(@"textFieldShouldBeginEditing");
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(PinCodeTextField *)textField {
    NSLog(@"textFieldShouldEndEditing");
    return YES;
}

- (void)textFieldDidBeginEditing:(PinCodeTextField *)textField {
    NSLog(@"textFieldDidBeginEditing");
}

- (void)textFieldDidEndEditing:(PinCodeTextField *)textField {
    NSLog(@"textFieldDidEndEditing %@", self.tfPinCode.text);
    if (self.tfPinCode.text.length) {
        isShowKeyboard = NO;
        [Utils showProgressViewWithString:@"" inView:self.view];
        [GlobalService comfirmWithPhoneNumber:[Utils getPhoneForCall:self.phoneNumber] code:self.tfPinCode.text completionHandler:^(BOOL status, int code, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Utils hideProgressViewInView:self.view];
                NSLog(@"%@", responseObject);
                if (status) {
                    // Thành công
                    [SPManager instance].myUser = [[UserModel alloc] initWithData:(NSDictionary *)responseObject];
                    [Utils writeCustomObjToUserDefaults:@"myUser" object:[SPManager instance].myUser];
                    MainTabBarController *mainTabbarVC = [[MainTabBarController alloc] init];
                    [UIApplication sharedApplication].keyWindow.rootViewController = mainTabbarVC;
                } else {
                    // Thất bại
                    [Utils showToastWithString:(NSString *)responseObject withView:self.view];
                }
                
                isShowKeyboard = YES;
            });
        }];
    }
}

- (void)textFieldValueChanged:(PinCodeTextField *)textField {
    NSLog(@"textFieldValueChanged");
}

- (BOOL)textFieldShouldReturn:(PinCodeTextField *)textField {
    return YES;
}



@end
