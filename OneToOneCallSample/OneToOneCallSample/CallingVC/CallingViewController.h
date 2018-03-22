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

typedef enum {
    CallingState_Call_Away     = 0,
    CallingState_InComing_Call = 1,
    CallingState_Calling       = 2,
    CallingState_Ended         = 3
} CallingState;

@interface CallingViewController : UIViewController<StringeeCallDelegate, StringeeRemoteViewDelegate>

// Outlet
@property (weak, nonatomic) IBOutlet UILabel *labelPhoneNumber;
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
@property (weak, nonatomic) IBOutlet UIButton *buttonCallPad;
@property (weak, nonatomic) IBOutlet UILabel *labelCallPad;
@property (weak, nonatomic) IBOutlet UIView *optionView;
@property (weak, nonatomic) IBOutlet UIButton *buttonDisableVideo;
@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchCamera;

// Variable

@property(assign, nonatomic) int timeSec;
@property(assign, nonatomic) int timeMin;
@property(strong, nonatomic) AVAudioPlayer *ringAudioPlayer;

// New SDK
@property(strong, nonatomic) NSString *username;
@property(strong, nonatomic) NSString *from;
@property(strong, nonatomic) NSString *to;
@property(strong, nonatomic) NSString *callId;
@property(strong, nonatomic) StringeeCall *stringeeCall;
@property(assign, nonatomic) BOOL isIncomingCall;
@property(assign, nonatomic) BOOL isCalling;
@property(assign, nonatomic) BOOL isVideoCall;
@property (weak, nonatomic) IBOutlet UIView *containRemoteView;

// Outlet Action
- (IBAction)endCallTapped:(UIButton *)sender;
- (IBAction)muteTapped:(UIButton *)sender;
- (IBAction)speakerTapped:(UIButton *)sender;
- (IBAction)acceptTapped:(UIButton *)sender;
- (IBAction)declineTapped:(UIButton *)sender;
- (IBAction)callpadTapped:(UIButton *)sender;
- (IBAction)disableEnableVideoTapped:(UIButton *)sender;
- (IBAction)switchCameraTapped:(UIButton *)sender;





@end
