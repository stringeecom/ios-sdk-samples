//
//  StringeeImplement.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "StringeeImplement.h"
#import "InstanceManager.h"
#import "CallManager.h"
#import "CallingViewController.h"

@implementation StringeeImplement {
    StringeeCall * seCall;
    StringeeCallState callState;
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
    
    if (!hasConnected) {
        hasConnected = !hasConnected;
        
        NSString *accessToken = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk3MDE5ODciLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5Nzg4Mzg3LCJ1c2VySWQiOiJpb3MifQ.Kpy4tqmPPyTU_22Yj-WBf_-cKWb5jQHqopC5dpUqD8Q";
        NSString *accessToken1 = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk3MDE5NjciLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5Nzg4MzY3LCJ1c2VySWQiOiJpb3MxIn0.IqRJOZX8I_xpejXlFzJ8QsPiO6P6UV2pKXCtgXkk1V4";
        NSString *accessToken2 = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk2MzYwMzEiLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5NzIyNDMxLCJ1c2VySWQiOiJodXlkbiJ9.d8m-jUDzwLqBO5r4HGRVAQS1hbimLdVBzOOpF862fEc";
//        [self.stringeeClient connectWithAccessToken:[self getMyAccessTokenForUserId:@"huydn"]];
        [self.stringeeClient connectWithAccessToken:accessToken];


    }
    
}

// Lấy về access token với userId
- (NSString *)getMyAccessTokenForUserId:(NSString *)myUserId {
    NSString * strUrl = [NSString stringWithFormat:@"https://v1.stringee.com/samples_and_docs/access_token/gen_access_token.php?userId=%@", myUserId];
    
    NSString *token = @"";
    NSError *error;
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (json) {
            token = json[@"access_token"];
        }
    }
    
    if (token.length) {
        return token;
    }
    
    return @"";
}

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    NSLog(@"requestAccessToken");
    //    NSString *accessToken = [self getMyAccessTokenForUserId:@"ios"];
    NSString *accessToken = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk3MDE5ODciLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5Nzg4Mzg3LCJ1c2VySWQiOiJpb3MifQ.Kpy4tqmPPyTU_22Yj-WBf_-cKWb5jQHqopC5dpUqD8Q";
    NSString *accessToken1 = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk3MDE5NjciLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5Nzg4MzY3LCJ1c2VySWQiOiJpb3MxIn0.IqRJOZX8I_xpejXlFzJ8QsPiO6P6UV2pKXCtgXkk1V4";
    NSString *accessToken2 = @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxLTE1MTk2MzYwMzEiLCJpc3MiOiJTS2VhOG14RHZkbk4zUEh1anBUWjJUSkNKQXFWTllIcUtxIiwiZXhwIjoxNTE5NzIyNDMxLCJ1c2VySWQiOiJodXlkbiJ9.d8m-jUDzwLqBO5r4HGRVAQS1hbimLdVBzOOpF862fEc";
//    [self.stringeeClient connectWithAccessToken:[self getMyAccessTokenForUserId:@"huydn"]];
    [self.stringeeClient connectWithAccessToken:accessToken];

}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].homeViewController) {
            [InstanceManager instance].homeViewController.title = stringeeClient.userId;
            [InstanceManager instance].homeViewController.btCall.enabled = YES;
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
    
    if (![CallManager sharedInstance].currentCall) {
        seCall = stringeeCall;
        seCall.callStateDelegate = self;
        seCall.callMediaDelegate = self;
        
        callState = -1;
        hasAnswered = NO;
        
        
        if (@available(iOS 10, *)) {
            // Callkit
            [[CallManager sharedInstance] reportIncomingCallForUUID:[NSUUID new] phoneNumber:seCall.from completionHandler:^(NSError *error) {
                if (!error) {
                    UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    CallingViewController *callingVC = (CallingViewController *)[mainSB instantiateViewControllerWithIdentifier:@"CallingViewController"];
                    callingVC.isOutgoingCall = NO;
                    callingVC.strUserId = stringeeCall.from;
                    callingVC.seCall = stringeeCall;
                    [[InstanceManager instance].homeViewController presentViewController:callingVC animated:YES completion:nil];
                    
                    [seCall initAnswerCall];
                } else {
                    [seCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                        NSLog(@"***** Reject - %@", message);
                    }];
                }
            }];
        } else {
            // Local push
            [self beginBackgroundTask];
            
            [seCall initAnswerCall];
            [self startRingingFrom:seCall.from];
            UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            CallingViewController *callingVC = (CallingViewController *)[mainSB instantiateViewControllerWithIdentifier:@"CallingViewController"];
            callingVC.isOutgoingCall = NO;
            callingVC.strUserId = stringeeCall.from;
            callingVC.seCall = stringeeCall;
            [[InstanceManager instance].homeViewController presentViewController:callingVC animated:YES completion:nil];
        }
        
    } else {
        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"***** Reject - %@", message);
        }];
    }
    
}

- (void)showLocalNotificationForMissCallState:(BOOL) isMissCall{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.repeatInterval = 0;
    if (isMissCall) {
        notification.soundName = UILocalNotificationDefaultSoundName;
        [notification setAlertBody:[NSString stringWithFormat:@"You missed the call from %@", ringingTimer.userInfo]];
    } else {
        notification.soundName = @"incoming_call.aif";
        [notification setAlertBody:[NSString stringWithFormat:@"%@ is Calling...", ringingTimer.userInfo]];

    }
    
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
    
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}


// MARK: - Private Method

- (void)checkAnswerCall {
    if (hasAnswered && audioIsActived) {
        [seCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"*****AnswercCall %@", message);
        }];
    }
}

- (NSTimer *)timerWithUserInfo:(NSString *)userInfo {
    if (!ringingTimer) {
        ringingTimer = [NSTimer scheduledTimerWithTimeInterval:8.0 target:self selector:@selector(showLocalNotificationForMissCallState:) userInfo:userInfo repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:ringingTimer forMode:NSRunLoopCommonModes];
        [ringingTimer fire];
    }
    return ringingTimer;
}

- (void)startRingingFrom:(NSString *)from {
    [self timerWithUserInfo:from];
}

- (void)stopRingingForMissCallState:(BOOL)isMissCall message:(NSString *)message {
    if (ringingTimer) {
        if (isMissCall) {
            [self showLocalNotificationForMissCallState:isMissCall];
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
    
    if (callState != STRINGEE_CALLSTATE_BUSY && callState != STRINGEE_CALLSTATE_END) {
        if (seCall.isIncomingCall && !hasAnswered) {
            [seCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"*****RejectCall %@", message);
            }];
        } else {
            [seCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"*****HangupCall %@", message);
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
    [seCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"*****Hangup - %@", message);
    }];
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


// MARK: - StringeeCallStateDelegate

- (void)didChangeState:(StringeeCall *)stringeeCall stringeeCallState:(StringeeCallState)state reason:(NSString *)reason {
    NSLog(@"StringeeCallState - %@", reason);
    callState = state;
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
                
            case STRINGEE_CALLSTATE_INIT: {
                [InstanceManager instance].callingViewController.labelConnecting.text = @"Init";
            } break;
                
            case STRINGEE_CALLSTATE_CALLING: {
                [InstanceManager instance].callingViewController.labelConnecting.text = @"Calling";
            } break;
                
            case STRINGEE_CALLSTATE_RINGING: {
                [InstanceManager instance].callingViewController.labelConnecting.text = @"Ringing";
            } break;
                
            case STRINGEE_CALLSTATE_STARTING: {
                [InstanceManager instance].callingViewController.labelConnecting.text = @"Starting";
            } break;
                
            case STRINGEE_CALLSTATE_CONNECTED: {
                [[InstanceManager instance].callingViewController startTimer];
            } break;
                
            case STRINGEE_CALLSTATE_BUSY: {
                [[InstanceManager instance].callingViewController stopTimer];
                [[InstanceManager instance].callingViewController dismissViewControllerAnimated:YES completion:nil];
            } break;
                
            case STRINGEE_CALLSTATE_END: {
                [[InstanceManager instance].callingViewController stopTimer];
                [[InstanceManager instance].callingViewController dismissViewControllerAnimated:YES completion:nil];
                if (@available(iOS 10, *)) {
                    [[CallManager sharedInstance] endCall];
                } else {
                    [self stopRingingForMissCallState:YES message:nil];
                }
                
            } break;
                
            default:
                break;
        }
    });
    
}

- (void)didAnsweredOnOtherDevice:(StringeeCall *)stringeeCall state:(StringeeCallState)state {
    NSLog(@"didAnsweredOnOtherDevice %ld", (long)state);
    [self stopRingingForMissCallState:YES message:@"The call has been controlled on other device"];
    [[InstanceManager instance].callingViewController stopTimer];
    [[InstanceManager instance].callingViewController dismissViewControllerAnimated:YES completion:nil];
}



@end
