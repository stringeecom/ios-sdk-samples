//
//  StringeeImplement.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "StringeeImplement.h"
#import "InstanceManager.h"

@implementation StringeeImplement {
    NSString *userId;
    BOOL isBusy;
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

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].mainViewController) {
            [InstanceManager instance].mainViewController.title = stringeeClient.userId;
        }
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);
}

- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    
    NSLog(@"incomingCallWithStringeeClient");
    
    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
    callingVC.username = @"Target User";
    callingVC.isIncomingCall = YES;
    callingVC.stringeeCall = stringeeCall;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
}

@end
