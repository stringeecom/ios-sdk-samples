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
        self.stringeeClient = [[StringeeClient alloc] initWithConnectionDelegate:self];
    }
    return self;
}

// MARK:- Private Method

// Kết nối tới Stringee Server
- (void)connectToStringeeServer {
    
    // Lấy userId ngẫu nhiên để lấy về access token. Để có thể gọi được thì các máy cần đăng nhập với userId khác nhau. Sample này nhiều người sử dụng nên hãy sử dụng userId mang đấu ấn riêng của bạn để trách bị trùng nhé :)
    int r = arc4random_uniform(74);
    userId = [NSString stringWithFormat:@"ios%d", r];
    
    NSString *accessToken = [self getMyAccessTokenForUserId:userId];
    [self.stringeeClient connectWithAccessToken:accessToken];
}

// Get access token witk fake userId
- (NSString *)getMyAccessTokenForUserId:(NSString *)myUserId {
//    NSString *strUrl = [NSString stringWithFormat:@"https://v1.stringee.com/samples/your_server/access_token/access_token-test.php?u=%@", myUserId];
    NSString *strUrl = [NSString stringWithFormat:@"https://v1.stringee.com/samples_and_docs/access_token/gen_access_token.php?userId=%@", myUserId]; //demo viettel
    
    NSString *token = @"";
    NSError *error;
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
    if (data) {
        NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
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



@end
