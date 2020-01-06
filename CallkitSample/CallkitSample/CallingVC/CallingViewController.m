//
//  SPCallingViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "CallingViewController.h"
#import "StringeeImplement.h"
#import "InstanceManager.h"

static int TIME_WINDOW = 2;
static int CALL_TIME_OUT = 60; // giây

@interface CallingViewController ()

@end

@implementation CallingViewController {
    NSTimer *timer;
    NSTimer *reportTimer;
    BOOL isMute;
    BOOL isSpeaker;
    
    // Stats report
    long long audioBw;
    double audioPLRatio;
    long long prevAudioPacketLost;
    long long prevAudioPacketReceived;
    double prevAudioTimeStamp;
    long long prevAudioBytes;
    
    BOOL isDecline;
    BOOL hasCreatedCall;
    BOOL hasAnsweredCall;
    BOOL hasConnectedMedia;
    
    NSTimer *timeoutTimer;
    int interval;
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
        
        // Bắt đầu check timeout cho cuộc gọi
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkCallTimeOut) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
    
        if (self.isIncomingCall) {
            self.buttonEndCall.hidden = YES;
            self.optionView.hidden = YES;
            
            if (!self.isCalling) {
                [self startSound];
            }
            self.labelUsername.text = self.stringeeCall.from;

            self.stringeeCall.delegate = self;
            [self.stringeeCall initAnswerCall];
        } else {
            
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            
            self.labelUsername.text = self.to;

            self.stringeeCall = [[StringeeCall alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient from:self.from to:self.to];
            
            self.stringeeCall.delegate = self;
            [self.stringeeCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message, NSString *data) {
                NSLog(@"makeCallWithCompletionHandler %@", message);
                if (!status) {
                    // Nếu make call không thành công thì kết thúc cuộc gọi
                    [self endCallAndDismissWithTitle:@"Cuộc gọi không thành công"];
                }
            }];
        }
        
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

//MARK: -  Action

- (IBAction)endCallTapped:(UIButton *)sender {
    [self hangup];
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
    [self answerCallWithAnimation:YES];
}

- (IBAction)declineTapped:(UIButton *)sender {
    [self decline];
}


// MARK: - Handle Call
- (void)checkCallTimeOut {
    NSLog(@"checkCallTimeOut");
    
    interval += 10;
    if (interval >= CALL_TIME_OUT && !timer) {
        // Quá thời gian quy định mà chưa có kết nối thoại thì sẽ kiểm tra để ngắt máy
        [[StringeeImplement instance] stopRingingWithMessage:@"Không có phản hồi"];
        [[CallManager sharedInstance] endCall];
        
        if (_isIncomingCall) {
            [self decline];
        } else {
            [self hangup];
        }
        
        [self endCallAndDismissWithTitle:@""];
    }
}

- (void)answerCallWithAnimation:(BOOL)isAnimation {
    [self stopSound];
    hasAnsweredCall = YES;
    if (isAnimation) {
        self.buttonDecline.hidden = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{
                self.buttonAccept.center = self.buttonEndCall.center;
                [self.buttonAccept setTransform:CGAffineTransformRotate(self.buttonAccept.transform, M_PI *3/4)];
                
            } completion:^(BOOL finished) {
                
                [self.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                    NSLog(@"%@", message);
                    if (!status) {
                        [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                    }
                }];
                
                self.buttonAccept.hidden = YES;
                self.buttonEndCall.hidden = NO;
                
                self.optionView.hidden = NO;
            }];
        });
    } else {
        self.buttonDecline.hidden = YES;
        self.buttonAccept.hidden = YES;
        self.buttonEndCall.hidden = NO;
        self.optionView.hidden = NO;
        
        [self.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            if (!status) {
                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
            }
        }];
    }

}

- (void)hangup {
    [self.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
        if (!status) {
            [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
        }
    }];
}

- (void)decline {
    isDecline = YES;
    [self stopSound];
    [self.stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
        if (!status) {
            [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
        }
    }];
}

// Show thông báo và kết thúc cuộc gọi
- (void)endCallAndDismissWithTitle:(NSString *)title {
    
    self.labelConnecting.text = title;
    self.view.userInteractionEnabled = NO;
    
    self.blurView.alpha = 0.4;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [self endStatsReports];
    
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    
    [self delayCallback:^{
        UIViewController *vc = self.presentingViewController;
        while (vc.presentingViewController) {
            vc = vc.presentingViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:^{
            [InstanceManager instance].callingViewController = nil;
        }];
        
    } forTotalSeconds:0.7];
}

// Thực hiện khối lệnh sau 1 khoảng thời gian
- (void)delayCallback:(void(^)(void))callback forTotalSeconds:(double)delayInSeconds {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

// MARK: - Handle Call

// Bắt đầu đếm thời gian cuộc gọi
- (void)startTimer {
    if (!timer) {
        self.isCalling = YES;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer fire];
    }

}

// Hàm nhảy dây
- (void)timerTick:(NSTimer *)timer
{
    self.timeSec++;
    if (self.timeSec == 60)
    {
        self.timeSec = 0;
        self.timeMin++;
    }
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    if (self.labelConnecting.hidden) {
        self.labelConnecting.hidden = NO;
    }
    self.labelConnecting.text= timeNow;
}

// Kết thúc đếm thời gian cuộc gọi
- (void)stopTimer {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timer invalidate];
    timer = nil;
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    self.labelConnecting.text= timeNow;
}

// MARK: - Check Internet Quality

// Bắt đầu kiểm tra chất lượng mạng
- (void)beginStatsReports {
    reportTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(statsReport) userInfo:nil repeats:YES];
}

// Kết thúc kiểm tra chất lượng mạng
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

// MARK: - Sound

- (void)startSound {

    if (@available(iOS 10, *)) {

    } else {
        NSString *soundFilePath;
        NSURL *soundFileURL;
        int loopIndex = 10;
        
        if (self.isIncomingCall) {
            soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_call"  ofType:@"aif"];
            soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            
            [self switchRouteTo:AVAudioSessionPortOverrideSpeaker];
            
            self.ringAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            self.ringAudioPlayer.numberOfLoops = loopIndex;
            [self.ringAudioPlayer prepareToPlay];
            [self.ringAudioPlayer play];
        }
    }
}

- (void)stopSound {
    [self.ringAudioPlayer stop];
    self.ringAudioPlayer = nil;
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

// MARK: - StringeeCallDelegate

- (void)didChangeSignalingState:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"*********Callstate: %ld", (long)signalingState);
    [StringeeImplement instance].signalingState = signalingState;
    
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
                [[StringeeImplement instance] stopRingingWithMessage:[NSString stringWithFormat:@"Bạn đã bỏ lỡ cuộc gọi từ %@", self.stringeeCall.from]];
                if (@available(iOS 10, *)) {
                    [[CallManager sharedInstance] endCall];
                }
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

- (void)didHandleOnAnotherDevice:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"didHandleOnAnotherDevice %ld", (long)signalingState);
    if (signalingState == SignalingStateAnswered) {
        [[StringeeImplement instance] stopRingingWithMessage:@"Cuộc gọi đã được điều khiển ở thiết bị khác"];
        [[CallManager sharedInstance] endCall];
        [self endCallAndDismissWithTitle:@"Cuộc gọi đã được điều khiển ở thiết bị khác"];
    }
}



@end
