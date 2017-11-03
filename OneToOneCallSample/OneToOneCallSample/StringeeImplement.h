//
//  StringeeImplement.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stringee/Stringee.h>

@interface StringeeImplement : NSObject<StringeeConnectionDelegate, StringeeIncomingCallDelegate>

@property (strong, nonatomic) StringeeClient *stringeeClient;

+ (StringeeImplement *)instance;

- (void)connectToStringeeServer;

@end
