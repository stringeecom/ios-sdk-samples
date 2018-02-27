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

@interface StringeeImplement : NSObject<StringeeConnectionDelegate, StringeeIncomingCallDelegate, CallManagerDelegate, StringeeCallStateDelegate, StringeeCallMediaDelegate>

@property (strong, nonatomic) StringeeClient *stringeeClient;
@property (strong, nonatomic) NSString *userId;


+ (StringeeImplement *)instance;

- (void)connectToStringeeServer;

- (void)stopRingingForMissCallState:(BOOL)isMissCall message:(NSString *)message;

@end
