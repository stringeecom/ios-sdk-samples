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

typedef NS_ENUM(NSInteger, CallScreenType) {
    CallScreenTypeIncomingVoice,
    CallScreenTypeIncomingVideo,
    CallScreenTypeOutgoingVoice,
    CallScreenTypeOutgoingVideo,
    CallScreenTypeCallingVoice,
    CallScreenTypeCallingVideo,
};

@interface CallingViewController : UIViewController<StringeeCallDelegate>

// Outlet
@property (weak, nonatomic) IBOutlet UILabel *lbStatus;
@property (weak, nonatomic) IBOutlet UILabel *lbUsername;
@property (weak, nonatomic) IBOutlet UIButton *btMute;
@property (weak, nonatomic) IBOutlet UIButton *btSpeaker;
@property (weak, nonatomic) IBOutlet UIView *blurView;
@property (weak, nonatomic) IBOutlet UIButton *btEnd;
@property (weak, nonatomic) IBOutlet UIButton *btReject;
@property (weak, nonatomic) IBOutlet UIButton *btAccept;
@property (weak, nonatomic) IBOutlet UIStackView *stackVoiceCallAction;
@property (weak, nonatomic) IBOutlet UIStackView *stackCallAction;
@property (weak, nonatomic) IBOutlet UIStackView *stackVideoCallAction;

@property (weak, nonatomic) IBOutlet UIButton *btVideo;
@property (weak, nonatomic) IBOutlet UIButton *btVideoMute;
@property (weak, nonatomic) IBOutlet UIButton *btCamera;
@property (weak, nonatomic) IBOutlet UIButton *btVideoEnd;
@property (weak, nonatomic) IBOutlet UIView *localContainer;

// Variable
@property(assign, nonatomic) int timeSec;
@property(assign, nonatomic) int timeMin;

// New SDK
@property(strong, nonatomic) StringeeCall *stringeeCall;

- (instancetype)initFrom:(NSString *)from to:(NSString *)to isVideo:(BOOL)isVideo;

- (instancetype)initWithCall:(StringeeCall *)call;

// Outlet Action
- (IBAction)endCallTapped:(UIButton *)sender;
- (IBAction)muteTapped:(UIButton *)sender;
- (IBAction)speakerTapped:(UIButton *)sender;
- (IBAction)acceptTapped:(UIButton *)sender;
- (IBAction)rejectTapped:(UIButton *)sender;

- (IBAction)videoTapped:(id)sender;
- (IBAction)videoMuteTapped:(id)sender;
- (IBAction)cameraTapped:(id)sender;
- (IBAction)videoEndTapped:(id)sender;

- (void)changeStateToAnswered;
- (BOOL)getMuteState;
- (void)setMuteState:(BOOL)mute;
- (void)endCallAndDismissWithTitle:(NSString *)title;

@end
