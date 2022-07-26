//
//  CallManager.h
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CallkitCall.h"
#import <Pushkit/pushkit.h>

@interface CallManager : NSObject

@property (nonatomic) CallkitCall *call;

+ (CallManager*)instance;

- (void)startCallWithPhone:(NSString*)phone calleeName:(NSString *)calleeName isVideo:(BOOL)isVideo stringeeCall:(StringeeCall *)stringeeCall;
- (void)handleIncomingPushEvent:(PKPushPayload *)payload completion:(void (^)(void))completion;
- (void)handleIncomingCallEvent:(StringeeCall *)stringeeCall;
- (void)answerCallkitCall;
- (void)endCall;

- (void)answer:(BOOL)shouldChangeUI;
- (void)reject:(StringeeCall *)call;
- (void)hangup:(StringeeCall *)call;
- (void)mute:(BOOL)mute completion:(void(^)(BOOL status))completion;

@end
