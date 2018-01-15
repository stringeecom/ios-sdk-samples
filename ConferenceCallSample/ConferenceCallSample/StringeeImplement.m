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
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

// MARK:- Stringee Connection Delegate

- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    [self.stringeeClient connectWithAccessToken:@"YOUR_ACCESS_TOKEN"];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"Đã kết nối tới Stringee Server");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([InstanceManager instance].mainViewController) {
            [InstanceManager instance].mainViewController.title = stringeeClient.userId;
        }
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"Đã mất kết nối tới Stringee Server");
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"Quá trình kết nối xảy ra lỗi - %@", message);
}



@end
