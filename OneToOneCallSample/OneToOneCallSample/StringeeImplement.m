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
    
    // Lấy userId ngẫu nhiên để lấy về access token. Để có thể gọi được thì các máy cần đăng nhập với userId khác nhau. Sample này nhiều người sử dụng nên hãy sử dụng userId mang đấu ấn riêng của bạn để trách bị trùng nhé :)
    //    userId = @"random1";
    int r = arc4random_uniform(74);
    userId = [NSString stringWithFormat:@"ios_%d", r];
    
    NSString *accessToken = [self getMyAccessTokenForUserId:userId];
    [self.stringeeClient connectWithAccessToken:accessToken];
}

// Lấy về access token với userId
- (NSString *)getMyAccessTokenForUserId:(NSString *)myUserId {
    NSString *strUrl = [NSString stringWithFormat:@"https://v1.stringee.com/samples/your_server/access_token/access_token-test.php?u=%@", myUserId];
    
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
    NSString *accessToken = [self getMyAccessTokenForUserId:userId];
    [self.stringeeClient connectWithAccessToken:accessToken];
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
    
    CTCallCenter *objCallCenter = [[CTCallCenter alloc] init];
    
    BOOL isSystemCalling = NO;
    
    if (!objCallCenter.currentCalls || (objCallCenter.currentCalls && objCallCenter.currentCalls.count == 0)) {
        isSystemCalling = NO;
    } else {
        isSystemCalling = YES;
    }
    
    isBusy = YES;
    
    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
    callingVC.username = @"Target User";
    callingVC.isIncomingCall = YES;
    callingVC.stringeeCall = stringeeCall;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    
    
    
    //    if (![InstanceManager instance].callingViewController && !isSystemCalling) {
    //
    //        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
    //        callingVC.callId = callId;
    //        callingVC.username = @"Target User";
    //        callingVC.from = from;
    //        callingVC.isVideoCall = isVideoCall;
    //        callingVC.to = to;
    //        callingVC.isIncomingCall = YES;
    //
    //        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    //    } else {
    //        StringeeCall *declineCall = [[StringeeCall alloc] initWithStringeeClient:_stringeeClient isIncomingCall:YES from:from to:to callId:callId];
    //        [declineCall hangup];
    //    }
}

@end
