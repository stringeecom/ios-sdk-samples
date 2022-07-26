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

@interface StringeeImplement : NSObject<StringeeConnectionDelegate, StringeeIncomingCallDelegate>

@property (strong, nonatomic) StringeeClient *stringeeClient;

+ (StringeeImplement *)instance;

- (void)connectToStringeeServer;
- (void)registerPushTokenIfNeedWithToken:(NSString *)deviceToken;

@end
