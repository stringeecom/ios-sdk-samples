//
//  SPCallViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "CallPadViewController.h"
//#import "PacketSender.h"
#import "InstanceManager.h"
#import "StringeeImplement.h"
#import <Stringee/Stringee.h>
#import "StringeeImplement.h"

@interface CallPadViewController ()

@end

@implementation CallPadViewController {
    NSString *strPhoneNumber;
}

// MARK: - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    strPhoneNumber = @"";
    self.labelPhoneNumber.text = @"";
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    strPhoneNumber = @"";
    self.labelPhoneNumber.text = @"";
    self.buttonClear.hidden = YES;
    
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
    }
    
    if (!self.labelPhoneNumber.text.length) {
        self.buttonClear.hidden = YES;
    }
}

- (IBAction)hideTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


// MARK: - Private method

- (void)typingWithText: (NSString *)text {
    
    strPhoneNumber = [strPhoneNumber stringByAppendingString:text];
    [self.labelPhoneNumber setText:strPhoneNumber];
    

    if (self.labelPhoneNumber.text.length) {
        self.buttonClear.hidden = NO;
    }
    
    if ([StringeeImplement instance].stringeeClient.hasConnected) {
        // Nếu đang gọi thì send DTMF
        
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
    } else {
        NSLog(@"Không có kết nối để gửi yêu cầu");
    }
}











@end
