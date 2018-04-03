//
//  StringeeImplement.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stringee/Stringee.h>
#import "CallManager.h"
#import <Intents/Intents.h>

@interface StringeeImplement : NSObject<StringeeConnectionDelegate, StringeeIncomingCallDelegate, CallManagerDelegate>

@property (strong, nonatomic) StringeeClient *stringeeClient;
@property (assign, nonatomic) SignalingState signalingState;

+ (StringeeImplement *)instance;

- (void)connectToStringeeServer;

- (void)stopRingingWithMessage:(NSString *)message;

- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity;

@end
