//
//  SPCallingViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Stringee/Stringee.h>

@interface CallingViewController : UIViewController<StringeeCallDelegate>

// Outlet
@property (weak, nonatomic) IBOutlet UILabel *labelConnecting;
@property (weak, nonatomic) IBOutlet UILabel *labelUsername;
@property (weak, nonatomic) IBOutlet UIButton *buttonMute;
@property (weak, nonatomic) IBOutlet UIButton *buttonSpeaker;
@property (weak, nonatomic) IBOutlet UIView *blurView;
@property (weak, nonatomic) IBOutlet UIButton *buttonEndCall;
@property (weak, nonatomic) IBOutlet UIButton *buttonDecline;
@property (weak, nonatomic) IBOutlet UIButton *buttonAccept;
@property (weak, nonatomic) IBOutlet UILabel *labelMute;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeaker;
@property (weak, nonatomic) IBOutlet UIImageView *imageInternetQuality;
@property (weak, nonatomic) IBOutlet UIView *optionView;

// Variable
@property(assign, nonatomic) int timeSec;
@property(assign, nonatomic) int timeMin;
@property(strong, nonatomic) AVAudioPlayer *ringAudioPlayer;

// New SDK
@property(strong, nonatomic) NSString *username;
@property(strong, nonatomic) NSString *from;
@property(strong, nonatomic) NSString *to;
@property(strong, nonatomic) StringeeCall *stringeeCall;
@property(assign, nonatomic) BOOL isIncomingCall;
@property(assign, nonatomic) BOOL isCalling;

// Outlet Action
- (IBAction)endCallTapped:(UIButton *)sender;
- (IBAction)muteTapped:(UIButton *)sender;
- (IBAction)speakerTapped:(UIButton *)sender;
- (IBAction)acceptTapped:(UIButton *)sender;
- (IBAction)declineTapped:(UIButton *)sender;

- (void)stopTimer;
- (void)startTimer;
- (void)answerCallWithAnimation:(BOOL)isAnimation;
- (void)decline;
- (void)endCallAndDismissWithTitle:(NSString *)title;

@end
