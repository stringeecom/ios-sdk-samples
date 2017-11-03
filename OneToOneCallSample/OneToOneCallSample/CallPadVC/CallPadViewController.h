//
//  SPCallViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 7/10/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Stringee/Stringee.h>

@interface CallPadViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) StringeeCall *stringeeCall;

@property (weak, nonatomic) IBOutlet UITextField *labelPhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonClear;
@property (weak, nonatomic) IBOutlet UIButton *buttonHide;

- (IBAction)oneTapped:(UIButton *)sender;
- (IBAction)twoTapped:(UIButton *)sender;
- (IBAction)threeTapped:(UIButton *)sender;
- (IBAction)fourTapped:(UIButton *)sender;
- (IBAction)fiveTapped:(UIButton *)sender;
- (IBAction)sixTapped:(UIButton *)sender;
- (IBAction)sevenTapped:(UIButton *)sender;
- (IBAction)eightTapped:(UIButton *)sender;
- (IBAction)nineTapped:(UIButton *)sender;
- (IBAction)zeroTapped:(UIButton *)sender;
- (IBAction)plusTapped:(UIButton *)sender;
- (IBAction)otherTapped:(UIButton *)sender;

- (IBAction)clearTapped:(UIButton *)sender;

- (IBAction)hideTapped:(UIButton *)sender;


@end
