//
//  CallManager.m
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import "CallManager.h"
#import <CallKit/CallKit.h>
#import <CallKit/CXError.h>
#import <Stringee/Stringee.h>
#import "InstanceManager.h"
#import <NSTEasyJSON/NSTEasyJSON.h>

@interface CallManager () <CXProviderDelegate>

@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, strong) CXCallController *callController;
@property (nonatomic) NSMutableDictionary *processedCalls;

@end


@implementation CallManager

// MARK: - Public Actions

+ (CallManager*)instance {
    static CallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CallManager alloc] init];
        [sharedInstance provider];
    });
    return sharedInstance;
}

- (void)reportIncomingCallForPhone:(NSString*)phone callerName:(NSString *)callerName isVideo:(BOOL)isVideo completion:(void(^)(bool status, NSUUID *uuid))completion {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.hasVideo = isVideo;
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:phone];
    update.localizedCallerName = callerName;
    NSUUID *uuid = [NSUUID new];
    
    __weak CallManager *weakSelf = self;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        CallManager *strongSelf = weakSelf;
        
        if (error == nil) {
            [strongSelf configureAudioSession];
            completion(true, uuid);
        } else {
            completion(false, nil);
        }
    }];
}

- (void)reportUpdateCallForPhone:(NSString*)phone callerName:(NSString *)callerName isVideo:(BOOL)isVideo uuid:(NSUUID *)uuid {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.hasVideo = isVideo;
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:phone];
    update.localizedCallerName = callerName;
    [self.provider reportCallWithUUID:uuid updated:update];
}

- (void)updateCallkitScreenForCall:(StringeeCall *)call uuid:(NSUUID *)uuid {
    [self reportUpdateCallForPhone:call.from callerName:call.fromAlias isVideo:call.isVideoCall uuid:uuid];
}

- (void)startCallWithPhone:(NSString*)phone calleeName:(NSString *)calleeName isVideo:(BOOL)isVideo stringeeCall:(StringeeCall *)stringeeCall {
    if (self.call != nil) {
        return;
    }
    
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:phone];
    self.call = [[CallkitCall alloc] initWithIncomingState:false startTimer:false];
    self.call.uuid = [NSUUID new];
    self.call.stringeeCall = stringeeCall;
    self.call.callId = stringeeCall.callId;
    
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:self.call.uuid handle:handle];
    [startCallAction setVideo:isVideo];
    startCallAction.contactIdentifier = calleeName;
    
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)endCall {
    if (self.call == nil || self.call.uuid == nil) {
        return;
    }
    
    [self includesCallsInRecents:true];
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:self.call.uuid];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:endCallAction];
    [self requestTransaction:transaction];
    
}

- (void)answerCallkitCall {
    if (self.call == nil || self.call.uuid == nil) {
        return;
    }
    
    [self includesCallsInRecents:true];
    CXAnswerCallAction *answerAction = [[CXAnswerCallAction alloc] initWithCallUUID:self.call.uuid];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:answerAction];
    [self requestTransaction:transaction];
}

- (void)holdCall:(BOOL)hold {
    if (self.call == nil || self.call.uuid == nil) {
        return;
    }
     
    CXSetHeldCallAction *holdCallAction = [[CXSetHeldCallAction alloc] initWithCallUUID:self.call.uuid onHold:hold];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:holdCallAction];
    [self requestTransaction:transaction];
    
}

- (void)requestTransaction:(CXTransaction*)transaction {
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"requestTransaction: %@", error.localizedDescription);
            // end callkit and delete current call
            [self endCall];
            self.call = nil;
            
            // dismiss CallingViewController if need
            if ([InstanceManager instance].callingVC != nil) {
                [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
            }
        }
    }];
}

- (void)configureAudioSession {
    NSError *err;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    if (err) {
        NSLog(@"Category Error %ld, %@",(long)err.code, err.localizedDescription);
    }
    
    [audioSession setMode:AVAudioSessionModeVideoChat error:&err];
    if (err) {
        NSLog(@"Mode Error %ld, %@",(long)err.code, err.localizedDescription);
    }
    
    double sampleRate = 44100.0;
    [audioSession setPreferredSampleRate:sampleRate error:&err];
    if (err) {
        NSLog(@"Sample Rate Error %ld, %@",(long)err.code, err.localizedDescription);
    }
    
    NSTimeInterval bufferDuration = .005;
    [audioSession setPreferredIOBufferDuration:bufferDuration error:&err];
    if (err) {
        NSLog(@"IO Buffer Duration Error %ld, %@",(long)err.code, err.localizedDescription);
    }
}

- (void)reportAFakeCall:(void (^)(void))completion {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.hasVideo = false;
    update.localizedCallerName = @"Expired Call";
    NSUUID *uuid = [NSUUID new];
    
    __weak CallManager *weakSelf = self;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Report fake call error: %@", error.localizedDescription);
        }
        
        CallManager *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf includesCallsInRecents:false];
            
            CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
            CXTransaction *transaction = [[CXTransaction alloc] init];
            [transaction addAction:endCallAction];
            [strongSelf.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
                if (error != nil) {
                    NSLog(@"End callkit error: %@", error.localizedDescription);
                }
            }];
            
            completion();
        });
    }];
}

- (void)startCheckingReceivingTimeoutOfStringeeCall {
    [self performSelector:@selector(checkReceivingTimeout) withObject:nil afterDelay:4];
}

- (void)stopCheckingReceivingTimeoutOfStringeeCall {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkReceivingTimeout) object:nil];
}

- (void)checkReceivingTimeout {
    NSLog(@"checkReceivingTimeout");
    if (self.call == nil) {
        return;
    }
    
    // if reported callkit but haven't received StringeeCall => End callkit
    if (self.call.uuid != nil && self.call.stringeeCall == nil) {
        [self endCall];
    }
}

// MARK: - Handle Call Logic

- (void)handleIncomingPushEvent:(PKPushPayload *)payload completion:(void (^)(void))completion {
    NSLog(@"handleIncomingPushEvent: %@", payload.dictionaryPayload);
    NSTEasyJSON *jsonData = [NSTEasyJSON withObject:payload.dictionaryPayload];
    NSTEasyJSON *callData = jsonData[@"data"][@"map"][@"data"][@"map"];
    
    NSString *callStatus = callData[@"callStatus"].stringValue;
    NSString *callId = callData[@"callId"].stringValue;
    NSString *pushType = jsonData[@"data"][@"map"][@"type"].stringValue;
    
    if (callStatus.length == 0 || callId.length == 0 || pushType.length == 0 || ![callStatus isEqualToString:@"started"] || ![pushType isEqualToString:@"CALL_EVENT"]) {
        [self reportAFakeCall:completion];
        return;
    }
    
    if (self.call != nil || [InstanceManager instance].callingVC != nil) {
        [self reportAFakeCall:completion];
        return;
    }

    NSNumber *serial = jsonData[@"data"][@"map"][@"data"][@"map"][@"serial"].numberValue;
    if ([self isCallProcessed:callId serial:serial.intValue]) {
        [self reportAFakeCall:completion];
        return;
    }
    
    self.call = [[CallkitCall alloc] initWithIncomingState:true startTimer:true];
    self.call.callId = callId;
    self.call.serial = serial.intValue;
    [self trackCall:self.call];
    
    NSString *alias = callData[@"from"][@"map"][@"alias"].stringValue;
    NSString *number = callData[@"from"][@"map"][@"number"].stringValue;

    NSString *phone;
    if (self.call.stringeeCall.from.length != 0) {
        phone = self.call.stringeeCall.from;
    } else {
        phone = number;
    }
    
    NSString *callerName;
    if (self.call.stringeeCall.fromAlias.length != 0) {
        callerName = self.call.stringeeCall.fromAlias;
    } else if (alias.length != 0) {
        callerName = alias;
    } else if (number.length != 0) {
        callerName = number;
    } else {
        callerName = @"Connecting Call...";
    }
    
    [self reportIncomingCallForPhone:phone callerName:callerName isVideo:false completion:^(bool status, NSUUID *uuid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status) {
                self.call.uuid = uuid;
                [[InstanceManager instance].callingVC.btAccept setEnabled:true];
                [[InstanceManager instance].callingVC.btReject setEnabled:true];

                if (self.call.stringeeCall != nil) {
                    [self updateCallkitScreenForCall:self.call.stringeeCall uuid:uuid];
                }
            } else {
                [self.call clean];
                self.call = nil;
            }
            
            completion();
        });
    }];
    
    [self startCheckingReceivingTimeoutOfStringeeCall];
}

- (void)handleIncomingCallEvent:(StringeeCall *)stringeeCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.call == nil && [InstanceManager instance].callingVC == nil) {
            [self showCallkitFor:stringeeCall];
            [self showCallingVCFor:stringeeCall];
            [stringeeCall initAnswerCall];
            [self answerCallIfConditionMatch:false];
            return;
        }
        
        if ([self.call.callId isEqualToString:stringeeCall.callId]) {
            if (self.call.uuid != nil) {
                [self updateCallkitScreenForCall:stringeeCall uuid:self.call.uuid];
            }
            
            self.call.stringeeCall = stringeeCall;
            [self showCallingVCFor:stringeeCall];
            [stringeeCall initAnswerCall];
            [self answerCallIfConditionMatch:false];
        } else {
            // handling another call, so reject new call
            CallkitCall *rejectedCall = [[CallkitCall alloc] initWithIncomingState:true startTimer:false];
            rejectedCall.callId = stringeeCall.callId;
            rejectedCall.serial = stringeeCall.serial;
            [self trackCall:rejectedCall];
            
            [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {}];
        }
    });
}

- (void)showCallkitFor:(StringeeCall *)stringeeCall {
    NSLog(@"INCOMING CALL - SHOW CALLKIT");
    self.call = [[CallkitCall alloc] initWithIncomingState:true startTimer:true];
    self.call.callId = stringeeCall.callId;
    self.call.stringeeCall = stringeeCall;
    self.call.serial = stringeeCall.serial;
    [self trackCall:self.call];
    
    [self reportIncomingCallForPhone:stringeeCall.from callerName:stringeeCall.fromAlias isVideo:stringeeCall.isVideoCall completion:^(bool status, NSUUID *uuid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status) {
                self.call.uuid = uuid;
                [[InstanceManager instance].callingVC.btAccept setEnabled:true];
                [[InstanceManager instance].callingVC.btReject setEnabled:true];
            } else {
                [self.call clean];
                self.call = nil;
            }
        });
    }];
}

- (void)showCallingVCFor:(StringeeCall *)stringeeCall {
    if ([InstanceManager instance].callingVC != nil) {
        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
        }];
        
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CallingViewController *callingVC = [[CallingViewController alloc] initWithCall:stringeeCall];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:true completion:nil];
    });
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset");
}

/// Called when the provider has been fully created and is ready to send actions and receive updates
- (void)providerDidBegin:(CXProvider *)provider NS_AVAILABLE_IOS(10.0) {
    NSLog(@"providerDidBegin");
}

// If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performStartCallAction");
    [self configureAudioSession];
    
    [self.provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:nil];
    [self.provider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:nil];

    [action fulfill];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performAnswerCallAction");
    if (self.call.uuid == nil || ![self.call.uuid.UUIDString isEqualToString:action.callUUID.UUIDString]) {
        [action fulfill];
        return;
    }

    self.call.answered = true;
    self.call.answerAction = action;
    [self.call clean];
    [self answerCallIfConditionMatch:true];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performEndCallAction");
    if (self.call.uuid == nil || ![self.call.uuid.UUIDString isEqualToString:action.callUUID.UUIDString]) {
        [action fulfill];
        return;
    }
    
    [self.call clean];
    if (self.call == nil || self.call.stringeeCall == nil) {
        [action fulfill];
        self.call = nil;
        return;
    }
    
    CallkitCall *tempCallkitCall = self.call;
    StringeeCall *tempStringeeCall = self.call.stringeeCall;
    self.call = nil;
    
    if (tempStringeeCall.signalingState != SignalingStateBusy || tempStringeeCall.signalingState != SignalingStateEnded) {
        if (tempCallkitCall.isIncoming && !tempCallkitCall.answered) {
            [self reject:tempStringeeCall];
        } else {
            [self hangup:tempStringeeCall];
        }
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action NS_AVAILABLE_IOS(10.0) {
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0) {
    if ([InstanceManager instance].callingVC == nil) {
        [action fail];
        return;
    }
    BOOL currentMuteState = [[InstanceManager instance].callingVC getMuteState];
    [self mute:!currentMuteState completion:^(BOOL status) {
        if (status) {
            [[InstanceManager instance].callingVC setMuteState:!currentMuteState];
            [action fulfill];
        } else {
            [action fail];
        }
    }];
}

- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action NS_AVAILABLE_IOS(10.0) {
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action NS_AVAILABLE_IOS(10.0) {
}

/// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action NS_AVAILABLE_IOS(10.0) {
    // React to the action timeout if necessary, such as showing an error UI.
}

/// Called when the provider's audio session activation state changes.
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession NS_AVAILABLE_IOS(10.0) {
    self.call.audioIsActived = true;
    [self answerCallIfConditionMatch:true];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession NS_AVAILABLE_IOS(10.0) {
    self.call.audioIsActived = false;

}

// MARK: - Call Actions

- (void)answer:(BOOL)shouldChangeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].callingVC != nil && shouldChangeUI) {
            [[InstanceManager instance].callingVC changeStateToAnswered];
        }
    });
    
    if (self.call.stringeeCall == nil) {
        return;
    }
    
    if (self.call.answerAction != nil) {
        [self.call.answerAction fulfill];
        self.call.answerAction = nil;
        return;
    }
    
    [self.call.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        if (!status) {
            if ([InstanceManager instance].callingVC != nil) {
                [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
                return;
            }
            
            [self endCall];
        }
    }];
}

- (void)reject:(StringeeCall *)call {
    self.call.rejected = true;
    
    StringeeCall *callNeedToReject;
    if (call != nil) {
        callNeedToReject = call;
    } else if (self.call.stringeeCall != nil) {
        callNeedToReject = self.call.stringeeCall;
    } else {
        if ([InstanceManager instance].callingVC != nil) {
            [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
        }
        return;
    }
    
    [callNeedToReject rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        if ([InstanceManager instance].callingVC != nil) {
            [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
            return;
        }
        
        [self endCall];
    }];
}

- (void)hangup:(StringeeCall *)call {
    StringeeCall *callNeedToReject;
    if (call != nil) {
        callNeedToReject = call;
    } else if (self.call.stringeeCall != nil) {
        callNeedToReject = self.call.stringeeCall;
    } else {
        if ([InstanceManager instance].callingVC != nil) {
            [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
        }
        return;
    }
    
    [callNeedToReject hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        if ([InstanceManager instance].callingVC != nil) {
            [[InstanceManager instance].callingVC endCallAndDismissWithTitle:nil];
            return;
        }
        
        [self endCall];
    }];
}

- (void)mute:(BOOL)mute completion:(void(^)(BOOL status))completion {
    if ([InstanceManager instance].callingVC == nil || self.call.stringeeCall == nil) {
        completion(false);
        return;
    }
    
    [self.call.stringeeCall mute:mute];
    completion(true);
}


- (void)answerCallIfConditionMatch:(BOOL)shouldChangeUI {
    if (self.call == nil) {
        return;
    }

    if (self.call.isIncoming && self.call.answered && (self.call.audioIsActived || self.call.answerAction != nil)) {
        // answer stringee call
        [self answer:shouldChangeUI];
    }
}




#pragma mark - Private Actions

- (CXProvider*)provider {
    if (!_provider) {
        CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"Stringee"];
        configuration.supportsVideo = YES;
        configuration.maximumCallGroups = 1;
        configuration.maximumCallsPerCallGroup = 1;
        configuration.supportedHandleTypes = [NSSet setWithObjects:@(CXHandleTypeGeneric), @(CXHandleTypePhoneNumber), nil];
        _provider = [[CXProvider alloc] initWithConfiguration:configuration];
        [_provider setDelegate:self queue:nil];
    }
    return _provider;
}

- (CXCallController*)callController {
    if (!_callController) {
        _callController = [[CXCallController alloc] init];
    }
    return _callController;
}

- (NSMutableDictionary *)processedCalls {
    if (!_processedCalls) {
        _processedCalls = [NSMutableDictionary new];
    }
    
    return _processedCalls;
}

- (void)includesCallsInRecents:(BOOL)include {
    if (@available(iOS 11.0, *)) {
        if (self.provider.configuration.includesCallsInRecents == include) {
            return;
        }
        self.provider.configuration.includesCallsInRecents = include;
    }
}

- (void)trackCall:(CallkitCall *)callkitCall {
    if (callkitCall == nil) {
        return;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@-%d", callkitCall.callId, callkitCall.serial];
    [self.processedCalls setObject:callkitCall forKey:key];
}

- (BOOL)isCallProcessed:(NSString *)callId serial:(int)serial {
    NSString *key = [NSString stringWithFormat:@"%@-%d", callId, serial];
    return [self.processedCalls objectForKey:key] != nil;
}


@end

