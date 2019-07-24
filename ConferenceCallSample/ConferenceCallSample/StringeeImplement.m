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
        int r = arc4random_uniform(74);
        userId = [NSString stringWithFormat:@"ios_%d", r];
    }
    return self;
}

// MARK:- Private Method

// Kết nối tới Stringee Server
- (void)connectToStringeeServer {
    NSString *token = [self getMyAccessTokenForUserId:userId];
    [self.stringeeClient connectWithAccessToken:token];
}

// MARK:- Stringee Connection Delegate

- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    NSString *token = [self getMyAccessTokenForUserId:userId];
    [self.stringeeClient connectWithAccessToken:token];
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


@end
