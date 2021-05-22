//
//  SPCallingViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "CallingViewController.h"
#import "CallPadViewController.h"
#import "StringeeImplement.h"
#import <Stringee/Stringee.h>
#import "InstanceManager.h"

static int TIME_WINDOW = 2; // Thời gian delay để tính chất lượng mạng

@interface CallingViewController ()

@end

@implementation CallingViewController {
    NSTimer *timer;
    BOOL isMute;
    NSTimer *reportTimer;
    
    // Stats report
    long long audioBw;
    double audioPLRatio;
    long long prevAudioPacketLost;
    long long prevAudioPacketReceived;
    double prevAudioTimeStamp;
    long long prevAudioBytes;
    
    BOOL hasCreatedCall;
    BOOL isSpeaker;
    BOOL videoIsDisable;
    BOOL hasAnsweredCall;
    BOOL hasConnectedMedia;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [InstanceManager instance].callingViewController = self;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!hasCreatedCall) {
        hasCreatedCall = !hasCreatedCall;
        self.labelUsername.text = self.username;
        
        if (self.isVideoCall || self.stringeeCall.isVideoCall) {
            self.buttonCallPad.hidden = YES;
            self.labelUsername.hidden = YES;
            self.labelPhoneNumber.hidden = YES;
            self.labelCallPad.text = @"Camera";
            self.view.backgroundColor = [UIColor blackColor];
            
        } else {
            self.buttonDisableVideo.hidden = YES;
            self.buttonSwitchCamera.hidden = YES;
            self.containRemoteView.hidden = YES;
            self.labelCallPad.text = @"Keypad";
        }
        
        StringeeAudioManager * audioManager = [StringeeAudioManager instance];
        [audioManager audioSessionSetActive:YES error:nil];
        
        if (!self.isIncomingCall) {
            self.labelPhoneNumber.text = [NSString stringWithFormat:@"Mobile: %@", self.to];
            
            self.stringeeCall = [[StringeeCall alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient from:self.from to:self.to];
            self.stringeeCall.isVideoCall = self.isVideoCall;
            self.stringeeCall.delegate = self;
            [self.stringeeCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message, NSString *data) {
                
                if (!status) {
                    // Nếu make call không thành công thì kết thúc cuộc gọi
                    [self endCallAndDismissWithTitle:@"Cuộc gọi không thành công"];
                }
                
            }];
        } else {
            self.labelPhoneNumber.text = [NSString stringWithFormat:@"Mobile: %@", self.stringeeCall.from];
            
            self.stringeeCall.delegate = self;
            [self.stringeeCall initAnswerCall];
        }
        
        
        if (!self.isCalling) {
            
            [self startSound];
            
            if (self.isIncomingCall) {
                self.buttonEndCall.hidden = YES;
                self.optionView.hidden = YES;
                
            } else {
                self.buttonAccept.hidden = YES;
                self.buttonDecline.hidden = YES;
            }
        }
    }
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.ringAudioPlayer stop];
}

// Bắt sự kiện rotate của device và thay đổi orientation của local video
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.stringeeCall) {
        [self.stringeeCall autoOrientationOfLocalVideoViewWithSize:size withTransitionCoordinator:coordinator];
        
        // Change frame of localVideoView
        [self.stringeeCall.localVideoView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    }
}

//MARK: - Action

- (IBAction)endCallTapped:(UIButton *)sender {
    [self removeVideoViews];
    [self.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
    }];
}

- (IBAction)muteTapped:(UIButton *)sender {
    if (isMute) {
        [self.stringeeCall mute:NO];
        isMute = NO;
        [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"icon_mute"] forState:UIControlStateNormal];
    } else {
        [self.stringeeCall mute:YES];
        isMute = YES;
        [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"icon_mute_selected"] forState:UIControlStateNormal];
    }
}

- (IBAction)speakerTapped:(UIButton *)sender {
    
    if (isSpeaker) {
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker"] forState:UIControlStateNormal];
        [[StringeeAudioManager instance] setLoudspeaker:NO];
        isSpeaker = NO;
        
    } else {
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker_selected"] forState:UIControlStateNormal];
        [[StringeeAudioManager instance] setLoudspeaker:YES];
        isSpeaker = YES;
    }
}


- (IBAction)acceptTapped:(UIButton *)sender {

    [self stopSound];
    
    self.buttonDecline.hidden = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.4 animations:^{
            self.buttonAccept.center = self.buttonEndCall.center;
            [self.buttonAccept setTransform:CGAffineTransformRotate(self.buttonAccept.transform, M_PI *3/4)];
            
        } completion:^(BOOL finished) {
            
            hasAnsweredCall = YES;
            [self.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"%@", message);
            }];
            
            self.buttonAccept.hidden = YES;
            self.buttonEndCall.hidden = NO;
            
            self.optionView.hidden = NO;
        }];
    });
    
}

- (IBAction)declineTapped:(UIButton *)sender {
    [self stopSound];
    [self removeVideoViews];
    [self.stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
    }];
}

- (IBAction)callpadTapped:(UIButton *)sender {
    CallPadViewController * callPad = [[CallPadViewController alloc] initWithNibName:@"CallPadViewController" bundle:nil];
    callPad.stringeeCall = self.stringeeCall;
   [self presentViewController:callPad animated:YES completion:nil];
}

- (IBAction)disableEnableVideoTapped:(UIButton *)sender {
    if (videoIsDisable) {
        videoIsDisable = NO;
        [self.buttonDisableVideo setBackgroundImage:[UIImage imageNamed:@"video_enable"] forState:UIControlStateNormal];
        [self.stringeeCall enableLocalVideo:YES];
    } else {
        videoIsDisable = YES;
        [self.buttonDisableVideo setBackgroundImage:[UIImage imageNamed:@"video_disable"] forState:UIControlStateNormal];
        [self.stringeeCall enableLocalVideo:NO];
    }
}

- (IBAction)switchCameraTapped:(UIButton *)sender {
    [self.stringeeCall switchCamera];
}

//MARK: - Private method

// Show thông báo và kết thúc cuộc gọi
- (void)endCallAndDismissWithTitle:(NSString *)title {
    
    self.labelConnecting.text = title;
    self.view.userInteractionEnabled = NO;
    
    StringeeAudioManager * audioManager = [StringeeAudioManager instance];
    [audioManager audioSessionSetActive:NO error:nil];
    
    self.blurView.alpha = 0.4;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [self endStatsReports];
    
    [self delayCallback:^{
        UIViewController *vc = self.presentingViewController;
        while (vc.presentingViewController) {
            vc = vc.presentingViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:^{
            [InstanceManager instance].callingViewController = nil;
        }];
        
    } forTotalSeconds:1];
}

// Thực hiện khối lệnh sau 1 khoảng thời gian
- (void)delayCallback: (void(^)(void))callback forTotalSeconds: (double)delayInSeconds {
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

// Xóa hết các videoview khi kết thúc cuộc gọi video
- (void)removeVideoViews {
    if (self.stringeeCall.remoteVideoView.superview) {
        [self.stringeeCall.remoteVideoView removeFromSuperview];
    }
    
    if (self.stringeeCall.localVideoView.superview) {
        [self.stringeeCall.localVideoView removeFromSuperview];
    }
}

// Bắt đầu đếm thời gian cuộc gọi
- (void)startTimer {
    
    self.isCalling = YES;
    
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer fire];
    }

}

// Hàm nhảy dây
- (void)timerTick:(NSTimer *)timer {
    self.timeSec++;
    if (self.timeSec == 60)
    {
        self.timeSec = 0;
        self.timeMin++;
    }
    
    if (self.labelConnecting.hidden) {
        self.labelConnecting.hidden = NO;
    }
    
    NSString *timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    self.labelConnecting.text= timeNow;
}

// Kết thúc đếm thời gian cuộc gọi
- (void)stopTimer{
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timer invalidate];
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    self.labelConnecting.text= timeNow;
}

- (void)switchRouteTo:(AVAudioSessionPortOverride)port {
    
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategorySoloAmbient error:&error];
    [session setActive: YES error:&error];
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:port
                                                       error:&error];
    if(error)
    {
        NSLog(@"Error: AudioSession cannot use speakers");
    }
}

- (void)beginStatsReports {
    reportTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(statsReport) userInfo:nil repeats:YES];
}

- (void)endStatsReports {
    [reportTimer invalidate];
    reportTimer = nil;
}

- (void)statsReport {
        [self.stringeeCall statsWithCompletionHandler:^(NSDictionary<NSString *,NSString *> *values) {
            [self checkAudioQualityWithStats:values];
        }];
}

// Đánh giá chất lượng mạng dựa trên các thông số
- (void)checkAudioQualityWithStats:(NSDictionary *)stats {
    
    NSTimeInterval audioTimeStamp = [[NSDate date] timeIntervalSince1970];
    
    NSNumber *byteReceived = [stats objectForKey:@"bytesReceived"];
    
    if (byteReceived.longLongValue != 0) {
        if (prevAudioTimeStamp == 0) {
            prevAudioTimeStamp = audioTimeStamp;
            
            prevAudioBytes = byteReceived.longLongValue;
        }
        
        if (audioTimeStamp - prevAudioTimeStamp > TIME_WINDOW) {
            
            // Tính tỉ lệ mất gói
            NSNumber *packetLost = stats[@"packetsLost"];
            NSNumber *packetsReceived = stats[@"packetsReceived"];
            
            if (prevAudioPacketReceived != 0) {
                long long pl = packetLost.longLongValue - prevAudioPacketLost;
                long long pr = packetsReceived.longLongValue - prevAudioPacketReceived;
                
                long long pt = pl + pr;
                
                if (pt > 0) {
                    audioPLRatio = (double)pl / (double)pt;
                }
            }
            
            prevAudioPacketLost = packetLost.longLongValue;
            prevAudioPacketReceived = packetsReceived.longLongValue;
            
            // Tính băng thông video
            audioBw = (long long) ((8 * (byteReceived.longLongValue - prevAudioBytes)) / (audioTimeStamp - prevAudioTimeStamp));
            prevAudioTimeStamp = audioTimeStamp;
            prevAudioBytes = byteReceived.longLongValue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([StringeeImplement instance].stringeeClient.hasConnected) {
                    if (audioBw >= 35000) {
                        
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"exellent"]];
                        
                    } else if (audioBw >= 25000 && audioBw < 35000) {
                        
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"good"]];
                        
                    } else if (audioBw > 15000 && audioBw < 25000) {
                        
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"average"]];
                        
                    } else {
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"poor"]];
                    }
                } else {
                    [self.imageInternetQuality setImage:[UIImage imageNamed:@"no_connect"]];
                }
                
                
            });
            
        }
    }
}

// MARK: - Play Ringing Sound

- (void)startSound
{
    NSString *soundFilePath;
    NSURL *soundFileURL;
    int loopIndex = 10;
    
    if (self.isIncomingCall) {
        soundFilePath = [[NSBundle mainBundle] pathForResource:@"sencha_ios_7"  ofType:@"mp3"];
        soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        [self switchRouteTo:AVAudioSessionPortOverrideSpeaker];
        
        self.ringAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        self.ringAudioPlayer.numberOfLoops = loopIndex;
        [self.ringAudioPlayer prepareToPlay];
        [self.ringAudioPlayer play];
    }
    
}

- (void)stopSound {
    [self.ringAudioPlayer stop];
    self.ringAudioPlayer = nil;
}


// MARK: - Stringee Call Delegate

//- (void)didChangeState:(StringeeCall *)stringeeCall stringeeCallState:(StringeeCallState)state reason:(NSString *)reason {
//
//    NSLog(@"*********Callstate: %d", state);
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        switch (state) {
//
//            case STRINGEE_CALLSTATE_INIT:
//                self.labelConnecting.text = @"Init...";
//                break;
//
//            case STRINGEE_CALLSTATE_CALLING:
//                self.labelConnecting.text = @"Calling...";
//                break;
//
//            case STRINGEE_CALLSTATE_RINGING:
//                self.labelConnecting.text = @"Ringing...";
//                break;
//
//            case STRINGEE_CALLSTATE_STARTING: {
//                self.labelConnecting.text = @"Starting...";
//            } break;
//
//            case STRINGEE_CALLSTATE_CONNECTED: {
//
//                [self StartTimer];
//                [self beginStatsReports];
//            } break;
//
//            case STRINGEE_CALLSTATE_BUSY: {
//
//                [self StopTimer];
//
//                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
//
//            } break;
//
//            case STRINGEE_CALLSTATE_END: {
//
//                [self StopTimer];
//
//                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
//
//            } break;
//
//        }
//    });
//}

- (void)didChangeSignalingState:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"*********Callstate: %ld", (long)signalingState);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (signalingState) {
                
            case SignalingStateCalling:
                self.labelConnecting.hidden = NO;
                self.labelConnecting.text = @"Đang gọi...";
                break;
                
            case SignalingStateRinging:
                self.labelConnecting.text = @"Đang đổ chuông...";
                break;
                
            case SignalingStateAnswered: {
                hasAnsweredCall = YES;
                if (hasConnectedMedia) {
                    [self startTimer];
                } else {
                    self.labelConnecting.text = @"Đang kết nối...";
                }
            } break;
                
            case SignalingStateBusy: {
                [self stopTimer];
                [self endCallAndDismissWithTitle:@"Số máy bận"];
            } break;
                
            case SignalingStateEnded: {
                [self stopTimer];
                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
            } break;
                
        }
    });
}

- (void)didChangeMediaState:(StringeeCall *)stringeeCall mediaState:(MediaState)mediaState {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (mediaState) {
            case MediaStateConnected:
                hasConnectedMedia = YES;
                if (hasAnsweredCall) {
                    [self startTimer];
                }
                [self beginStatsReports];
                
                break;
            case MediaStateDisconnected:
                break;
            default:
                break;
        }
    });
}


- (void)didReceiveLocalStream:(StringeeCall *)stringeeCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        [stringeeCall.localVideoView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [self.view insertSubview:stringeeCall.localVideoView atIndex:0];
    });
}

- (void)didReceiveRemoteStream:(StringeeCall *)stringeeCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        [stringeeCall.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView.bounds.size.width, self.containRemoteView.bounds.size.height)];
        stringeeCall.remoteVideoView.delegate = self;
        [self.containRemoteView addSubview:stringeeCall.remoteVideoView];
    });
}

// MARK: - Stringee RemoteView Delegate
- (void)videoView:(StringeeRemoteVideoView *)videoView didChangeVideoSize:(CGSize)size {
    NSLog(@"didChangeVideoSize %f - %f", size.width, size.height);
    
    // Get width and height of superview
    CGFloat superWidth = self.containRemoteView.bounds.size.width;
    CGFloat superHeight = self.containRemoteView.bounds.size.height;
    
    CGFloat newWidth;
    CGFloat newHeight;
    
    if (size.width > size.height) {
        newWidth = superWidth;
        newHeight = newWidth * size.height / size.width;
        
        [videoView setFrame:CGRectMake(0, (superHeight - newHeight) / 2, newWidth, newHeight)];
        
    } else {
        newHeight = superHeight;
        newWidth = newHeight * size.width / size.height;
        
        [videoView setFrame:CGRectMake((superWidth - newWidth) / 2, 0, newWidth, newHeight)];
    }
}



@end
