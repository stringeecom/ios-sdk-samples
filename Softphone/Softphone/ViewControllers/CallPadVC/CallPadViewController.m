//
//  SPCallViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "CallPadViewController.h"
#import "Stringee/Stringee.h"
#import "CallingViewController.h"
#import "SPManager.h"
#import "Utils.h"
#import "ContactModel.h"
#import "StringeeImplement.h"

@interface CallPadViewController ()

@end

@implementation CallPadViewController {
    NSString * strPhoneNumber;
}

// MARK: - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    strPhoneNumber = @"";
    self.labelPhoneNumber.text = @"";
    self.labelUsername.text = @"";
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestue:)];
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.numberOfTapsRequired = 1;
    [self.labelPhoneNumber addGestureRecognizer:tapGesture];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    strPhoneNumber = @"";
    self.labelPhoneNumber.text = @"";
    self.labelUsername.text = @"";
    self.buttonClear.hidden = YES;
    
    if (self.isShowInCall) {
        self.buttonCall.hidden = YES;
        self.buttonHide.hidden = NO;
    } else {
        self.buttonCall.hidden = NO;
        self.buttonHide.hidden = YES;
        
    }
    
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// MARK: - Action

- (IBAction)oneTapped:(UIButton *)sender {
    [self typingWithText:@"1"];
}

- (IBAction)twoTapped:(UIButton *)sender {
    [self typingWithText:@"2"];
}

- (IBAction)threeTapped:(UIButton *)sender {
    [self typingWithText:@"3"];
}

- (IBAction)fourTapped:(UIButton *)sender {
    [self typingWithText:@"4"];
    
}

- (IBAction)fiveTapped:(UIButton *)sender {
    [self typingWithText:@"5"];
    
}

- (IBAction)sixTapped:(UIButton *)sender {
    [self typingWithText:@"6"];
    
}

- (IBAction)sevenTapped:(UIButton *)sender {
    [self typingWithText:@"7"];
    
}

- (IBAction)eightTapped:(UIButton *)sender {
    [self typingWithText:@"8"];
    
}

- (IBAction)nineTapped:(UIButton *)sender {
    [self typingWithText:@"9"];
    
}

- (IBAction)zeroTapped:(UIButton *)sender {
    [self typingWithText:@"0"];
    
}

- (IBAction)plusTapped:(UIButton *)sender {
    [self typingWithText:@"*"];
    
}

- (IBAction)otherTapped:(UIButton *)sender {
    [self typingWithText:@"#"];
}

- (IBAction)clearTapped:(UIButton *)sender {
    if (strPhoneNumber.length) {
        strPhoneNumber = [strPhoneNumber substringToIndex:(strPhoneNumber.length - 1)];
        self.labelPhoneNumber.text = strPhoneNumber;
        self.labelUsername.text = [self findUsernameWithPhone:strPhoneNumber];
    }
    
    if (!self.labelPhoneNumber.text.length) {
        self.buttonClear.hidden = YES;
    }
}

- (IBAction)hideTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)callTapped:(UIButton *)sender {
    
    NSString * toPhoneNumber = self.labelPhoneNumber.text;
    
    if (!toPhoneNumber.length) {
        // không nhập số - Kiểm tra tiếp có số đã lưu chưa
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *toPhoneNumber = [prefs stringForKey:@"toPhoneNumber"];
        
        if (toPhoneNumber && toPhoneNumber.length) {
            self.labelPhoneNumber.text = toPhoneNumber;
            strPhoneNumber = toPhoneNumber;
            self.labelUsername.text = [self findUsernameWithPhone:toPhoneNumber];
            
            if (self.labelPhoneNumber.text.length) {
                self.buttonClear.hidden = NO;
            } else {
                self.buttonClear.hidden = YES;
            }
            
        } else {
            [Utils showToastWithString:@"Bạn cần nhập vào số điện thoại" withView:self.view];
        }
        return;
    }
    
    if ([StringeeImplement instance].stringeeClient.hasConnected && ![[SPManager instance] isSystemCall]) {
        toPhoneNumber = [Utils getPhoneForCall:toPhoneNumber];
        
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isIncomingCall = NO;
        if (self.labelUsername.text.length) {
            callingVC.username = self.labelUsername.text;
        } else {
            callingVC.username = self.labelPhoneNumber.text;
        }
        callingVC.from = [[SPManager instance] getNumberForCallOut];;
        callingVC.to = toPhoneNumber;
        callingVC.isAppToApp = NO;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    } else {
        [Utils showToastWithString:@"Không có kết nối" withView:self.view];
    }
    
    // Lưu lại số cũ
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:toPhoneNumber forKey:@"toPhoneNumber"];
    [prefs synchronize];
}

// MARK: - Private method

-(void) typingWithText: (NSString *) text {
    
    strPhoneNumber = [strPhoneNumber stringByAppendingString:text];
    [self.labelPhoneNumber setText:strPhoneNumber];
    
    if (!self.isShowInCall) {
        self.labelUsername.text = [self findUsernameWithPhone:strPhoneNumber];
    } else {
        
        CallDTMF dtmf;
        
        if ([text isEqualToString:@"0"]) {
            dtmf = CallDTMFZero;
        }
        else if ([text isEqualToString:@"1"]) {
            dtmf = CallDTMFOne;
        }
        else if ([text isEqualToString:@"2"]) {
            dtmf = CallDTMFTwo;
        }
        else if ([text isEqualToString:@"3"]) {
            dtmf = CallDTMFThree;
        }
        else if ([text isEqualToString:@"4"]) {
            dtmf = CallDTMFFour;
        }
        else if ([text isEqualToString:@"5"]) {
            dtmf = CallDTMFFive;
        }
        else if ([text isEqualToString:@"6"]) {
            dtmf = CallDTMFSix;
        }
        else if ([text isEqualToString:@"7"]) {
            dtmf = CallDTMFSeven;
        }
        else if ([text isEqualToString:@"8"]) {
            dtmf = CallDTMFEight;
        }
        else if ([text isEqualToString:@"9"]) {
            dtmf = CallDTMFNine;
        }
        else if ([text isEqualToString:@"*"]) {
            dtmf = CallDTMFStar;
        }
        else {
            dtmf = CallDTMFPound;
        }
        
        [self.stringeeCall sendDTMF:dtmf completionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"callDTMF - status: %d - message: %@", status, message);
        }];
    }
    
    if (self.labelPhoneNumber.text.length) {
        self.buttonClear.hidden = NO;
    }
}

- (NSString *)findUsernameWithPhone:(NSString *)phone {
    
    NSLog(@"phone: %@", phone);
    
    // Nếu số điện thoại tồn tại thì mới tìm
    if (phone.length) {
        
        for (NSString *key in [SPManager instance].listKeys) {
            NSArray *contactOfSection = [[SPManager instance].dicSections objectForKey:key];
            for (ContactModel *contactModel in contactOfSection) {
                if ([contactModel.phone_display isEqualToString:phone] || [contactModel.phone_call isEqualToString:phone]) {
                    return contactModel.name;
                }
            }
        }
    }
    
    return  @"";
}

-(void) handleGestue:(UITapGestureRecognizer *) tapGesture {
    
    if (self.isShowInCall) {
        return;
    }
    
    UILabel * targetLabel = (UILabel *)[tapGesture view];
    [self.view.window makeKeyWindow];
    [self becomeFirstResponder];
    [[UIMenuController sharedMenuController] setTargetRect:CGRectMake(targetLabel.frame.size.width / 2, targetLabel.frame.origin.y, 1, 1) inView:targetLabel];
    
    UIMenuItem * copyTtem = [[UIMenuItem alloc] initWithTitle:@"Sao chép" action:@selector(copyAction:)];
    
    UIMenuItem * pasteItem = [[UIMenuItem alloc] initWithTitle:@"Dán" action:@selector(pasteAction:)];
    
    [[UIMenuController sharedMenuController] setMenuItems:@[copyTtem, pasteItem]];
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

-(BOOL) canBecomeFirstResponder {
    return YES;
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    
    if (self.labelPhoneNumber.text.length) {
        if (action == @selector(pasteAction:) || action == @selector(copyAction:)) {
            result = YES;
        }
    } else {
        if (action == @selector(pasteAction:)) {
            result = YES;
        }
    }
    
    return result;
}

-(void) pasteAction:(id) sender {
    
    UIPasteboard * board = [UIPasteboard generalPasteboard];
    
    if (board.string.length) {
        
        NSString *strTarget = [board.string stringByReplacingOccurrencesOfString:@"+" withString:@""];
        
        if ([Utils validateString:strTarget withPattern:@"^[0-9]+$"]) {
            strPhoneNumber = strTarget;
            [self.labelPhoneNumber setText:strPhoneNumber];
            self.labelUsername.text = [self findUsernameWithPhone:strPhoneNumber];
            
            if (self.labelPhoneNumber.text.length) {
                self.buttonClear.hidden = NO;
            } else {
                self.buttonClear.hidden = YES;
            }
        } else {
            [Utils showToastWithString:@"Chuỗi cần dán không hợp lệ" withView:self.view];
        }
    }
}

-(void) copyAction:(id) sender {
    if (self.labelPhoneNumber.text.length) {
        UIPasteboard * board = [UIPasteboard generalPasteboard];
        board.string = self.labelPhoneNumber.text;
    }
}



@end
