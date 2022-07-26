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
    NSString *_deviceToken;
    BOOL _registeredPush;
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
    }
    return self;
}

// Kết nối tới stringee server
-(void) connectToStringeeServer {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

- (void)registerPushTokenIfNeedWithToken:(NSString *)deviceToken {
    if (deviceToken != nil || deviceToken.length > 0) {
        _deviceToken = deviceToken;
    }
    
    if (_deviceToken == nil || _deviceToken.length == 0 || _registeredPush || !self.stringeeClient.hasConnected) {
        return;
    }
        
    // Note: remember to pass isProduction depends on environment you are working on (development or production)
    [self.stringeeClient registerPushForDeviceToken:_deviceToken isProduction:false isVoip:true completionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"registerPush: %@", message);
        _registeredPush = status;
    }];
}

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].homeVC) {
            [InstanceManager instance].homeVC.title = stringeeClient.userId;
            [InstanceManager instance].homeVC.btCall.enabled = YES;
            [InstanceManager instance].homeVC.btVideoCall.enabled = YES;
        }
        
        [self registerPushTokenIfNeedWithToken:nil];
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        [InstanceManager instance].homeVC.btCall.enabled = NO;
    });
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);
}

- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    [[CallManager instance] handleIncomingCallEvent:stringeeCall];
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

@end
