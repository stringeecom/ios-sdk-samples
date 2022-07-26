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

static int CALL_TIME_OUT = 60; // giây

@interface CallingViewController ()

@end

@implementation CallingViewController {
    NSTimer *timer;
    NSTimer *timeoutTimer;
    int interval;
    
    BOOL _isIncoming;
    BOOL _isVideo;
    BOOL _isMute;
    BOOL _isSpeaker;
    BOOL _localVideoEnabled;
    BOOL _ended;
    SignalingState _signalingState;
    MediaState _mediaState;
    NSString *_from;
    NSString *_to;
    
    BOOL _mediaFirstTimeConnected;
}

- (instancetype)initFrom:(NSString *)from to:(NSString *)to isVideo:(BOOL)isVideo
{
    self = [super initWithNibName:@"CallingViewController" bundle:nil];
    if (self) {
        _isIncoming = false;
        _isVideo = isVideo;
        _from = from;
        _to = to;
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCall:(StringeeCall *)call
{
    self = [super initWithNibName:@"CallingViewController" bundle:nil];
    if (self) {
        self.stringeeCall = call;
        call.delegate = self;
        _isIncoming = true;
        _isVideo = call.isVideoCall;
        _from = call.from;
        _to = call.to;
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [InstanceManager instance].callingVC = self;
    _localVideoEnabled = true;
    _signalingState = SignalingStateCalling;
    _mediaState = MediaStateDisconnected;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:_isVideo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionRouteChange) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [self startTimeoutTimer];
    [self setupUI];
    
    if (!_isIncoming) {
        // make call
        self.stringeeCall = [[StringeeCall alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient from:_from to:_to];
        self.stringeeCall.isVideoCall = _isVideo;
        self.stringeeCall.delegate = self;
        [self.stringeeCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message, NSString *data) {
            if (status) {
                // Sucess => show callkit screen
                [[CallManager instance] startCallWithPhone:_to calleeName:_to isVideo:_isVideo stringeeCall:self.stringeeCall];
            } else {
                [self endCallAndDismissWithTitle:nil];
            }
        }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

// MARK: -  Public

- (void)changeStateToAnswered {
    _signalingState = SignalingStateAnswered;
    [self updateScreen];
}

- (BOOL)getMuteState {
    return _isMute;
}

- (void)setMuteState:(BOOL)mute {
    _isMute = mute;
}

- (void)endCallAndDismissWithTitle:(NSString *)title {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_ended) {
            return;
        }
        _ended = !_ended;
        
        self.lbStatus.text = title != nil ? title : @"Kết thúc cuộc gọi";
        self.blurView.alpha = 0.4;
        self.view.userInteractionEnabled = NO;
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        
        [self stopTimeoutTimer];
        [self stopTimer];
        
        [[CallManager instance] endCall];
                
        UIViewController *vc = self.presentingViewController;
        while (vc.presentingViewController) {
            vc = vc.presentingViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:^{
            [InstanceManager instance].callingVC = nil;
        }];
            
    });
    
}

// MARK: -  UI

- (void)setupUI {
    if (_isIncoming) {
        self.lbUsername.text = self.stringeeCall.fromAlias.length > 0 ? self.stringeeCall.fromAlias : self.stringeeCall.from;
    } else {
        self.lbUsername.text = self.stringeeCall.toAlias.length > 0 ? self.stringeeCall.toAlias : self.stringeeCall.to;
    }
    
    [self updateScreen];
}

- (void)updateScreen {
    CallScreenType screenType = [self getScreenType];
    switch (screenType) {
        case CallScreenTypeOutgoingVoice:
            [self changeStackViewButton:self.btAccept hide:true];
            [self changeStackViewButton:self.btReject hide:true];
            [self changeStackViewButton:self.btEnd hide:false];
            [self.lbUsername setHidden:false];
            [self.lbStatus setHidden:false];
            [self.localContainer setHidden:true];
            [self.stackVideoCallAction setHidden:true];
            [self.stackVoiceCallAction setHidden:false];
            break;
        case CallScreenTypeOutgoingVideo:
            [self changeStackViewButton:self.btAccept hide:true];
            [self changeStackViewButton:self.btReject hide:true];
            [self changeStackViewButton:self.btEnd hide:false];
            [self.lbUsername setHidden:false];
            [self.lbStatus setHidden:false];
            [self.localContainer setHidden:true];
            [self.stackVideoCallAction setHidden:true];
            [self.stackVoiceCallAction setHidden:false];
            break;
        case CallScreenTypeIncomingVoice:
            [self changeStackViewButton:self.btAccept hide:false];
            [self changeStackViewButton:self.btReject hide:false];
            [self changeStackViewButton:self.btEnd hide:true];
            [self.lbUsername setHidden:false];
            [self.lbStatus setHidden:true];
            [self.localContainer setHidden:true];
            [self.stackVideoCallAction setHidden:true];
            [self.stackVoiceCallAction setHidden:true];
            break;
        case CallScreenTypeIncomingVideo:
            [self changeStackViewButton:self.btAccept hide:false];
            [self changeStackViewButton:self.btReject hide:false];
            [self changeStackViewButton:self.btEnd hide:true];
            [self.lbUsername setHidden:false];
            [self.lbStatus setHidden:true];
            [self.localContainer setHidden:true];
            [self.stackVideoCallAction setHidden:true];
            [self.stackVoiceCallAction setHidden:true];
            break;
        case CallScreenTypeCallingVoice:
            [self changeStackViewButton:self.btAccept hide:true];
            [self changeStackViewButton:self.btReject hide:true];
            [self changeStackViewButton:self.btEnd hide:false];
            [self.lbUsername setHidden:false];
            [self.lbStatus setHidden:false];
            [self.localContainer setHidden:true];
            [self.stackVideoCallAction setHidden:true];
            [self.stackVoiceCallAction setHidden:false];
            break;
        case CallScreenTypeCallingVideo:
            [self changeStackViewButton:self.btAccept hide:true];
            [self changeStackViewButton:self.btReject hide:true];
            [self changeStackViewButton:self.btEnd hide:true];
            [self.lbUsername setHidden:true];
            [self.lbStatus setHidden:true];
            [self.localContainer setHidden:false];
            [self.stackVideoCallAction setHidden:false];
            [self.stackVoiceCallAction setHidden:true];
            break;
        default:
            break;
    }
    
}

- (CallScreenType)getScreenType {
    CallScreenType screenType;
    if (_signalingState == SignalingStateAnswered) {
        screenType = _isVideo ? CallScreenTypeCallingVideo : CallScreenTypeCallingVoice;
    } else {
        if (_isIncoming) {
            screenType = _isVideo ? CallScreenTypeIncomingVideo : CallScreenTypeIncomingVoice;
        } else {
            screenType = _isVideo ? CallScreenTypeOutgoingVideo : CallScreenTypeOutgoingVoice;
        }
    }
    
    return screenType;
}

//MARK: -  Action

- (IBAction)endCallTapped:(UIButton *)sender {
    [[CallManager instance] hangup:nil];
}

- (IBAction)muteTapped:(UIButton *)sender {
    _isMute = !_isMute;
    [[CallManager instance] mute:_isMute completion:^(BOOL status) {
        NSString *imageName = _isMute ? @"ic-mute-selected-new" : @"ic-mute-new";
        [self.btMute setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }];
}

- (IBAction)speakerTapped:(UIButton *)sender {
    _isSpeaker = !_isSpeaker;
    [[StringeeAudioManager instance] setLoudspeaker:_isSpeaker];
    NSString *imageName = _isSpeaker ? @"ic-speaker-selected-new" : @"ic-speaker-new";
    [self.btSpeaker setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}


- (IBAction)acceptTapped:(UIButton *)sender {
    if (@available(iOS 14, *)) {
        [[CallManager instance] answerCallkitCall];
    } else {
        [[CallManager instance] answer:true];
    }
}

- (IBAction)rejectTapped:(UIButton *)sender {
    [[CallManager instance] reject:nil];
}

- (IBAction)videoEndTapped:(id)sender {
    [[CallManager instance] hangup:nil];
}

- (IBAction)cameraTapped:(id)sender {
    [self.stringeeCall switchCamera];
}

- (IBAction)videoMuteTapped:(id)sender {
    _isMute = !_isMute;
    [[CallManager instance] mute:_isMute completion:^(BOOL status) {
        NSString *imageName = _isMute ? @"ic-mute-selected-new" : @"ic-mute-new";
        [self.btVideoMute setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }];
}

- (IBAction)videoTapped:(id)sender {
    _localVideoEnabled = !_localVideoEnabled;
    [self.stringeeCall enableLocalVideo:_localVideoEnabled];
    NSString *imageName = _localVideoEnabled ? @"ic-video-new" : @"ic-video-selected-new";
    [self.btVideo setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

// MARK: - Timer

- (void)startTimeoutTimer {
    if (timeoutTimer != nil) {
        return;
    }
    
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkCallTimeOut) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
    [timeoutTimer fire];
}

- (void)stopTimeoutTimer {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}
- (void)checkCallTimeOut {
    NSLog(@"checkCallTimeOut");
    interval += 10;
    if (interval >= CALL_TIME_OUT && !timer) {
        if (_isIncoming) {
            [[CallManager instance] reject:nil];
        } else {
            [[CallManager instance] hangup:nil];
        }
    }
}

- (void)startTimer {
    if (_signalingState != SignalingStateAnswered || _mediaState != MediaStateConnected) {
        return;
    }
    
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer fire];
    }
}

- (void)timerTick:(NSTimer *)timer {
    self.timeSec++;
    if (self.timeSec == 60)
    {
        self.timeSec = 0;
        self.timeMin++;
    }
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    if (self.lbStatus.hidden) {
        self.lbStatus.hidden = NO;
    }
    self.lbStatus.text= timeNow;
}

// Kết thúc đếm thời gian cuộc gọi
- (void)stopTimer {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timer invalidate];
    timer = nil;
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    self.lbStatus.text= timeNow;
}

// MARK: - StringeeCallDelegate

- (void)didChangeSignalingState:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"*********Callstate: %ld", (long)signalingState);
    _signalingState = signalingState;
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (signalingState) {
            case SignalingStateCalling:
                self.lbStatus.text = @"Calling";
                break;
            case SignalingStateRinging:
                self.lbStatus.text = @"Ringing";
                break;
            case SignalingStateAnswered:
                [self updateScreen];
                [self startTimer];
                break;
            case SignalingStateBusy:
                [self endCallAndDismissWithTitle:@"Busy"];
                break;
            case SignalingStateEnded:
                [self endCallAndDismissWithTitle:nil];
                break;
        }
    });
}

- (void)didChangeMediaState:(StringeeCall *)stringeeCall mediaState:(MediaState)mediaState {
    dispatch_async(dispatch_get_main_queue(), ^{
        _mediaState = mediaState;
        switch (mediaState) {
            case MediaStateConnected:
                [self startTimer];
                
                // if call's type is video then route audio to speaker
                if (!_mediaFirstTimeConnected) {
                    _mediaFirstTimeConnected = !_mediaFirstTimeConnected;
                    if (_isVideo) {
                        [self routeToSpeakerIfNeeded];
                    }
                    [self stopTimeoutTimer];
                }
                
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
        stringeeCall.localVideoView.frame = CGRectMake(0, 0, self.localContainer.frame.size.width, self.localContainer.frame.size.height);
        [self.localContainer insertSubview:stringeeCall.localVideoView atIndex:0];
    });
}

- (void)didReceiveRemoteStream:(StringeeCall *)stringeeCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        stringeeCall.remoteVideoView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view insertSubview:stringeeCall.remoteVideoView atIndex:0];
    });
}

- (void)didHandleOnAnotherDevice:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"didHandleOnAnotherDevice %ld", (long)signalingState);
    if (signalingState == SignalingStateAnswered || signalingState == SignalingStateBusy || signalingState == SignalingStateEnded) {
        [self endCallAndDismissWithTitle:@"Call is handled on another device"];
    }
}

// MARK: - AudioSession

- (void)handleAudioSessionRouteChange {
    NSLog(@"handleAudioSessionRouteChange");
    dispatch_async(dispatch_get_main_queue(), ^{
        AVAudioSessionRouteDescription *currentRoute = [AVAudioSession sharedInstance].currentRoute;
        AVAudioSessionPortDescription *portDes = currentRoute.outputs.firstObject;
        if (portDes.portType == AVAudioSessionPortBuiltInSpeaker) {
            _isSpeaker = true;
        } else if (portDes.portType == AVAudioSessionPortHeadphones || portDes.portType == AVAudioSessionPortBuiltInReceiver) {
            _isSpeaker = false;
        }
        
        NSString *imageName = _isSpeaker ? @"ic-speaker-selected-new" : @"ic-speaker-new";
        [self.btSpeaker setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    });
}

- (void)routeToSpeakerIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        AVAudioSessionRouteDescription *currentRoute = [AVAudioSession sharedInstance].currentRoute;
        AVAudioSessionPortDescription *portDes = currentRoute.outputs.firstObject;
        if (portDes.portType != AVAudioSessionPortHeadphones && ![self isBluetoothConnected]) {
            [[StringeeAudioManager instance] setLoudspeaker:true];
            _isSpeaker = true;
        }
    });
}

- (BOOL)isBluetoothConnected {
    NSArray<AVAudioSessionPortDescription *> *availableInputs = [AVAudioSession sharedInstance].availableInputs;
    if (availableInputs == nil || availableInputs.count == 0) {
        return false;
    }
    
    for (AVAudioSessionPortDescription *input in availableInputs) {
        if (input.portType == AVAudioSessionPortBluetoothLE || input.portType == AVAudioSessionPortBluetoothHFP || input.portType == AVAudioSessionPortBluetoothA2DP) {
            return true;
        }
    }
    
    return false;
}


// MARK: - Utils

- (void)delayCallback:(void(^)(void))callback forTotalSeconds:(double)delayInSeconds {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

- (void)changeStackViewButton:(UIButton *)button hide:(BOOL)hide {
    button.alpha = hide ? 0 : 1;
    button.enabled = !hide;
}

@end
