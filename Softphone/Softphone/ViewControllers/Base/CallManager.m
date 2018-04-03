//
//  CallManager.m
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import "CallManager.h"
#import <Stringee/Stringee.h>

@interface CallManager () <CXProviderDelegate>

@property (nonatomic, strong) CXProvider NS_AVAILABLE_IOS(10.0) *provider;
@property (nonatomic, strong) CXCallController NS_AVAILABLE_IOS(10.0) *callController;

@end


@implementation CallManager

+ (CallManager*)sharedInstance {
    static CallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CallManager alloc] init];
        if (@available(iOS 10, *)) {
            [sharedInstance provider];
        }
    });
    return sharedInstance;
}

- (void)reportIncomingCallForUUID:(NSUUID*)uuid phoneNumber:(NSString*)phoneNumber callerName:(NSString *)callerName isVideoCall:(BOOL)isVideoCall completionHandler:(void(^)(NSError *error))completionHandler NS_AVAILABLE_IOS(10.0) {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.hasVideo = isVideoCall;
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:phoneNumber];
    update.localizedCallerName = callerName;
    __weak CallManager *weakSelf = self;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.currentCall = uuid;
            [self configureAudioSession];
        }
        completionHandler(error);
    }];
}

- (void)startCallWithPhoneNumber:(NSString*)phoneNumber calleeName:(NSString *)calleeName isVideoCall:(BOOL)isVideoCall NS_AVAILABLE_IOS(10.0) {
    
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:phoneNumber];
    self.currentCall = [NSUUID new];
    
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:self.currentCall handle:handle];
    startCallAction.video = isVideoCall;
    startCallAction.contactIdentifier = calleeName;
    
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
    
//    CXCallObserver *callObserver = [[CXCallObserver alloc] init];
}

- (void)endCall {
    if (@available(iOS 10, *)) {
        if (self.currentCall) {
            CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:self.currentCall];
            CXTransaction *transaction = [[CXTransaction alloc] init];
            [transaction addAction:endCallAction];
            [self requestTransaction:transaction];
        }
    }
}

- (void)holdCall:(BOOL)hold {
    if (@available(iOS 10, *)) {
        if (self.currentCall) {
            CXSetHeldCallAction *holdCallAction = [[CXSetHeldCallAction alloc] initWithCallUUID:self.currentCall onHold:hold];
            CXTransaction *transaction = [[CXTransaction alloc] init];
            [transaction addAction:holdCallAction];
            [self requestTransaction:transaction];
        }
    }
}

- (void)requestTransaction:(CXTransaction*)transaction NS_AVAILABLE_IOS(10.0) {
    if (@available(iOS 10, *)) {
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
                if (self.delegate && [self.delegate respondsToSelector:@selector(callDidFail:)]) {
                    [self.delegate callDidFail:error];
                }
            }
        }];
    }
}

#pragma mark - Getters

- (CXProvider*)provider {
    if (!_provider) {
        CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"Stringee"];
        configuration.supportsVideo = YES;
        configuration.maximumCallsPerCallGroup = 1;
//        configuration.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypeGeneric)];
        configuration.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypeGeneric],[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
        _provider = [[CXProvider alloc] initWithConfiguration:configuration];
        [_provider setDelegate:self queue:nil];
    }
    return _provider;
}

- (CXCallController*)callController NS_AVAILABLE_IOS(10.0) {
    if (!_callController) {
        _callController = [[CXCallController alloc] init];
    }
    return _callController;
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider NS_AVAILABLE_IOS(10.0) {
    NSLog(@"providerDidReset");
}

/// Called when the provider has been fully created and is ready to send actions and receive updates
- (void)providerDidBegin:(CXProvider *)provider NS_AVAILABLE_IOS(10.0) {
    NSLog(@"providerDidBegin");
}

// If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performStartCallAction");
    
    //todo: configure audio session
    [self configureAudioSession];
    
    //todo: start network call
    [self.provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:nil];
    [self.provider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:nil];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidAnswer)]) {
        [self.delegate callDidAnswer];
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performAnswerCallAction");
    
    //todo: configure audio session
    //    [self configureAudioSession];
    
    //todo: answer network call
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidAnswer)]) {
        [self.delegate callDidAnswer];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performEndCallAction");
    
    //todo: stop audio
    //todo: end network call
    self.currentCall = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidEnd)]) {
        [self.delegate callDidEnd];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"performSetHeldCallAction");
    
    if (action.isOnHold) {
        //todo: stop audio
    } else {
        //todo: start audio
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidHold:)]) {
        [self.delegate callDidHold:action.isOnHold];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0) {
    if (self.delegate && [self.delegate respondsToSelector:@selector(muteTapped:)]) {
        [self.delegate muteTapped:action];
    }
    
    [action fulfill];
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
    //todo: start audio
    // Start call audio media, now that the audio session has been activated after having its priority boosted.
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidActiveAudioSession)]) {
        [self.delegate callDidActiveAudioSession];
    }
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession NS_AVAILABLE_IOS(10.0) {
    /*
     Restart any non-call related audio now that the app's audio session has been
     de-activated after having its priority restored to normal.
     */
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidDeactiveAudioSession)]) {
        [self.delegate callDidDeactiveAudioSession];
    }
}

- (void)configureAudioSession {
    
    NSError *err;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    
    if (err) {
        NSLog(@"Category Error %ld, %@",(long)err.code, err.localizedDescription);
    }
    
    [audioSession setMode:AVAudioSessionModeVoiceChat error:&err];
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

@end

