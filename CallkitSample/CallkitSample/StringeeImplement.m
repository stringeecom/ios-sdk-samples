//
//  StringeeImplement.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "StringeeImplement.h"
#import "CallManager.h"
#import "CallingViewController.h"
#import "InstanceManager.h"

@implementation StringeeImplement {
    StringeeCall * seCall;
    BOOL hasAnswered;
    BOOL hasConnected;
    BOOL audioIsActived;
    
    NSTimer *ringingTimer;
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
}

static StringeeImplement *sharedMyManager = nil;

+ (StringeeImplement *)instance {
    @synchronized(self) {
        if (sharedMyManager == nil) {
            sharedMyManager = [[self alloc] init];
        }
    }
    return sharedMyManager;
}

- (id)init {
    self = [super init];
    if (self) {
        // Khởi tạo StringeeClient
        self.stringeeClient = [[StringeeClient alloc] initWithConnectionDelegate:self];
        self.stringeeClient.incomingCallDelegate = self;
        [CallManager sharedInstance].delegate = self;
    }
    return self;
}

// Kết nối tới stringee server
-(void) connectToStringeeServer {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].homeViewController) {
            [InstanceManager instance].homeViewController.title = stringeeClient.userId;
            [InstanceManager instance].homeViewController.btCall.enabled = YES;
        }
        
        // Nếu chưa đăng ký nhận push thì đăng ký hoặc khi logout sau đó conect với tài khoản khác thì cũng cần đăng ký
        if (![InstanceManager instance].hasRegisteredToReceivePush) {
            [self.stringeeClient registerPushForDeviceToken:[InstanceManager instance].deviceToken isProduction:NO isVoip:YES completionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"%@", message);
                if (status) {
                    [InstanceManager instance].hasRegisteredToReceivePush = YES;
                }
            }];
        }
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        [InstanceManager instance].homeViewController.btCall.enabled = NO;
    });
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);
}

- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    
    if (![CallManager sharedInstance].currentCall && ![InstanceManager instance].callingViewController) {
        
        seCall = stringeeCall;
        self.signalingState = -1;
        hasAnswered = NO;
        
        if (@available(iOS 10, *)) {
            // Callkit
            [[CallManager sharedInstance] reportIncomingCallForUUID:[NSUUID new] phoneNumber:seCall.from completionHandler:^(NSError *error) {
                if (!error) {
                    
                    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
                    callingVC.isIncomingCall = YES;
                    callingVC.username = stringeeCall.from;
                    callingVC.stringeeCall = stringeeCall;
                    
                    [self delayCallback:^{
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:NO completion:nil];
                    } forTotalSeconds:0.5];
                    
                } else {
                    [seCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                        NSLog(@"***** Reject - %@", message);
                    }];
                }
            }];
        } else {
            // Local push
            [self beginBackgroundTask];
            
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [self startRinging];
            }
            
            CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
            callingVC.isIncomingCall = YES;
            callingVC.username = stringeeCall.from;
            callingVC.stringeeCall = stringeeCall;
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
        }
        
    } else {
        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"***** Reject - %@", message);
        }];
    }
}

// MARK: - Private Method

- (void)delayCallback:(void(^)(void))callback forTotalSeconds:(double)delayInSeconds {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

- (void)checkAnswerCall {
    if (hasAnswered && audioIsActived) {
        [[InstanceManager instance].callingViewController answerCallWithAnimation:NO];
    }
}

- (void)startRinging {
    if (!ringingTimer) {
        ringingTimer = [NSTimer scheduledTimerWithTimeInterval:8.0 target:self selector:@selector(displayRingingNotification) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:ringingTimer forMode:NSRunLoopCommonModes];
        [ringingTimer fire];
    }}


- (void)displayRingingNotification {
    NSString *message = [NSString stringWithFormat:@"%@ Đang gọi...", seCall.from];
    [self displayLocalNotificationWithMessage:message soundName:@"incoming_call.aif"];
}

- (void)displayLocalNotificationWithMessage:(NSString *)message soundName:(NSString *)soundName {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.repeatInterval = 0;
    notification.soundName = soundName;
    [notification setAlertBody:message];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}



- (void)stopRingingWithMessage:(NSString *)message {
    
    if (ringingTimer) {
        
        if (message.length) {
            [self displayLocalNotificationWithMessage:message soundName:UILocalNotificationDefaultSoundName];
        }
        
        CFRunLoopStop(CFRunLoopGetCurrent());
        [ringingTimer invalidate];
        ringingTimer = nil;
        
        [self endBackgroundTask];
    }
}

- (void)beginBackgroundTask {
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

// MARK: - CallManagerDelegate
- (void)callDidAnswer {
    NSLog(@"callDidAnswer");
    hasAnswered = YES;
    [self checkAnswerCall];
}

- (void)callDidEnd {
    NSLog(@"callDidEnd");
    
    if (self.signalingState != SignalingStateBusy && self.signalingState != SignalingStateEnded) {
        if (seCall.isIncomingCall && !hasAnswered) {
            [[InstanceManager instance].callingViewController decline];
        } else {
            [[InstanceManager instance].callingViewController.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"*****HangupCall %@", message);
                if (!status) {
                    [[InstanceManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                }
            }];
        }
    }
    hasAnswered = NO;
}

- (void)callDidHold:(BOOL)isOnHold {
    NSLog(@"callDidHold");
}

- (void)callDidFail:(NSError *)error {
    NSLog(@"callDidFail");
    [[InstanceManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
}

- (void)callDidActiveAudioSession {
    NSLog(@"callDidActiveAudioSession");
    audioIsActived = YES;
    [self checkAnswerCall];
}

- (void)callDidDeactiveAudioSession {
    NSLog(@"callDidDeactiveAudioSession");
    audioIsActived = NO;
}



@end
