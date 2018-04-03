//
//  StringeeImplement.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "StringeeImplement.h"
#import "SPManager.h"
#import "CallManager.h"
#import "CallingViewController.h"
#import "Utils.h"
#import "GlobalService.h"
#import "Constants.h"


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
    
    long long timeStamp = (long long)[[NSDate date] timeIntervalSince1970];
    
    NSLog(@"timeStamp %lld", timeStamp);
    NSLog(@"expireTime %lld", [SPManager instance].myUser.expireTime);
    
    if ([SPManager instance].myUser.accessToken.length && timeStamp < [SPManager instance].myUser.expireTime) {
        [self.stringeeClient connectWithAccessToken:[SPManager instance].myUser.accessToken];
    } else {
        [self getAccessTokenAndConnect];
    }
}

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    NSLog(@"requestAccessToken");
    [self getAccessTokenAndConnect];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SPManager instance].historyViewController.navigationItem.title = @"Lịch sử";
        [[SPManager instance].settingViewController.tblSetting reloadData];
        
        if (![SPManager instance].hasRegisteredToReceivePush) {
            [self.stringeeClient registerPushForDeviceToken:[SPManager instance].deviceToken isProduction:isProductionMode isVoip:YES completionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"%@", message);
                if (status) {
                    [SPManager instance].hasRegisteredToReceivePush = YES;
                }
            }];
        }
        
        if ([SPManager instance].userActivity) {
            [self createCallFollowUserActivity:[SPManager instance].userActivity];
        }
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SPManager instance].historyViewController) {
            [SPManager instance].historyViewController.navigationItem.title = @"Connecting...";
        }
    });
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);
}

- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    
    if (![CallManager sharedInstance].currentCall && ![SPManager instance].callingViewController && ![[SPManager instance] isSystemCall]) {
        seCall = stringeeCall;
        //        stringeeCall.delegate = self;
        self.signalingState = -1;
        hasAnswered = NO;
        
        if (@available(iOS 10, *)) {
            // Callkit
            BOOL isAppToApp = NO; // Là cuộc gọi giữa 2 ứng dụng chứ ko phải là từ ứng dụng ra số di động hay từ số di động vào ứng dụng
            //            NSString *phoneNumber;
            
            // Xử lý cho trường hợp callkit lưu lịch sử cuộc gọi và khi click vào lịch sử cuộc gọi thì chúng ta cần biết kiểu cuộc gọi
            if (stringeeCall.callType == CallTypeInternalIncomingCall) {
                isAppToApp = YES;
                //                phoneNumber = [@"IC" stringByAppendingString:seCall.from];
            } else {
                //                phoneNumber = [@"EX" stringByAppendingString:seCall.from];
            }
            
            [[CallManager sharedInstance] reportIncomingCallForUUID:[NSUUID new] phoneNumber:seCall.from callerName:seCall.from isVideoCall:stringeeCall.isVideoCall completionHandler:^(NSError *error) {
                if (!error) {
                    
                    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
                    callingVC.isIncomingCall = YES;
                    callingVC.username = stringeeCall.from;
                    callingVC.stringeeCall = stringeeCall;
                    callingVC.isVideoCall = stringeeCall.isVideoCall;
                    [Utils delayCallback:^{
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
            callingVC.isVideoCall = stringeeCall.isVideoCall;
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
        }
        
    } else {
        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"***** Reject - %@", message);
        }];
    }
}


// MARK: - Private Method

- (void)checkAnswerCall {
    if ([SPManager instance].callingViewController.isIncomingCall && hasAnswered && audioIsActived) {
        [[SPManager instance].callingViewController answerCallWithAnimation:NO];
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
    
    //    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
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

- (void)getAccessTokenAndConnect {
    if ([SPManager instance].myUser.token.length) {
        [GlobalService getAccessTokenWithToken:[SPManager instance].myUser.token completionHandler:^(BOOL status, int code, id responseObject) {
            NSLog(@"getAccessTokenAndConnect %@", responseObject);
            if (status) {
                NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)responseObject];
                [data setObject:[SPManager instance].myUser.token forKey:@"token"];
                
                [SPManager instance].myUser = [[UserModel alloc] initWithData:data];
                [Utils writeCustomObjToUserDefaults:@"myUser" object:[SPManager instance].myUser];
                
                [self.stringeeClient connectWithAccessToken:[SPManager instance].myUser.accessToken];
            } else {
                [self getAccessTokenAndConnect];
            }
        }];
    }
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
            [[SPManager instance].callingViewController decline];
        } else {
            [[SPManager instance].callingViewController.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"*****HangupCall %@", message);
                if (!status) {
                    [[SPManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
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
    //    [seCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
    //        NSLog(@"*****Hangup - %@", message);
    //    }];
    [[SPManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
    
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

- (void)muteTapped:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"muteTapped");
    if (@available(iOS 10, *)) {
        [[SPManager instance].callingViewController mute];
    }
}

- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity {
    if (@available(iOS 10, *)) {
        // Lấy thông tin cuộc gọi
        INInteraction *interaction = userActivity.interaction;
        INIntent *intent = interaction.intent;
        BOOL isVideoCall = NO;
        NSString *to;
        if ([intent isKindOfClass:[INStartAudioCallIntent class]]) {
            NSLog(@"AUDIO %@", ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value);
            to = ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value;
        } else if ([intent isKindOfClass:[INStartVideoCallIntent class]]) {
            NSLog(@"VIDEO %@", ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value);
            to = ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value;
            isVideoCall = YES;
        }
        
        //        NSString *prefix = [to substringToIndex:2];
        //        to = [to substringFromIndex:2];
        //        NSLog(@"prefix %@ - to %@", prefix, to);
        
        if (isVideoCall) {
            [self createCallToNumber:to isVideoCall:isVideoCall isCallout:NO];
        } else {
            UIAlertControllerStyle style;
            
            if (IS_IPHONE) {
                // iphone
                style = UIAlertControllerStyleActionSheet;
            } else {
                // ipad + tv...
                style = UIAlertControllerStyleAlert;
            }
            
            UIAlertController *confirmAlert = [UIAlertController
                                               alertControllerWithTitle:nil
                                               message:nil
                                               preferredStyle:style];
            
            UIAlertAction *callAppToAppAction = [UIAlertAction actionWithTitle:@"Gọi qua Softphone" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self createCallToNumber:to isVideoCall:isVideoCall isCallout:NO];
            }];
            
            UIAlertAction *callAppToPhoneAction = [UIAlertAction actionWithTitle:@"Gọi ra số di động" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self createCallToNumber:to isVideoCall:isVideoCall isCallout:YES];
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil];
            [confirmAlert addAction:callAppToAppAction];
            [confirmAlert addAction:callAppToPhoneAction];
            [confirmAlert addAction:cancelAction];
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:confirmAlert animated:YES completion:nil];
        }
    }
    
    [SPManager instance].userActivity = nil;
}

- (void)createCallToNumber:(NSString *)to isVideoCall:(BOOL)isVideoCall isCallout:(BOOL)isCallout{
    if (![[SPManager instance] isSystemCall] && to.length) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isIncomingCall = NO;
        callingVC.username = to;
        if (isCallout) {
            callingVC.from = [[SPManager instance] getNumberForCallOut];
        } else {
            callingVC.from = [StringeeImplement instance].stringeeClient.userId;
        }
        callingVC.isAppToApp = !isCallout;
        callingVC.to = to;
        callingVC.isVideoCall = isVideoCall;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    } else {
        [Utils showToastWithString:@"Đang diễn ra cuộc gọi hệ thống" withView:[[SPManager instance].contactViewController view]];
    }
}






@end
