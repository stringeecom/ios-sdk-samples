//
//  LoginViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "StringeeImplement.h"
#import "Constants.h"
#import "Utils.h"
#import "ConfirmViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.btLogin.layer.cornerRadius = 5;
    self.btLogin.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)loginTapped:(UIButton *)sender {
    if (!self.tfPhoneNumber.text.length) {
        [Utils showToastWithString:@"Bạn cần nhập số điện thoại" withView:self.view];
        return;
    }
    
    [Utils showProgressViewWithString:@"" inView:self.view];
    
    [GlobalService loginWithPhoneNumber:[Utils getPhoneForCall:self.tfPhoneNumber.text] completionHandler:^(BOOL status, int code, id responseObject) {
    
        [Utils hideProgressViewInView:self.view];
        
        if (status) {
            ConfirmViewController *confirmVC = [[ConfirmViewController alloc] initWithNibName:@"ConfirmViewController" bundle:nil];
            confirmVC.phoneNumber = self.tfPhoneNumber.text;
            UINavigationController *confirmNavi = [[UINavigationController alloc] initWithRootViewController:confirmVC];
            [self presentViewController:confirmNavi animated:YES completion:nil];
        } else {
            NSLog(@"Register failed... %@", (NSString *)responseObject);
            [Utils showToastWithString:(NSString *)responseObject withView:self.view];
        }
    }];
    
}

// MARK:- Keyboard movements

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat bottomSpaceFromLoginBtToContainer = SCR_HEIGHT - (self.btLogin.frame.origin.y + self.btLogin.frame.size.height);
    
    if (bottomSpaceFromLoginBtToContainer < (keyboardSize.height + 20)) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect f = self.view.frame;
            f.origin.y = -(keyboardSize.height + 20 - bottomSpaceFromLoginBtToContainer);
            self.view.frame = f;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
}
@end
