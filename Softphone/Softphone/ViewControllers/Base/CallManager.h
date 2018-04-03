//
//  CallManager.h
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CallKit/CallKit.h>
#import <CallKit/CXError.h>

@protocol CallManagerDelegate <NSObject>

- (void)callDidAnswer;
- (void)callDidEnd;
- (void)callDidHold:(BOOL)isOnHold;
- (void)callDidFail:(NSError *)error;
- (void)callDidActiveAudioSession;
- (void)callDidDeactiveAudioSession;
- (void)muteTapped:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0);
@end

@interface CallManager : NSObject

+ (CallManager*)sharedInstance;

- (void)reportIncomingCallForUUID:(NSUUID*)uuid phoneNumber:(NSString*)phoneNumber callerName:(NSString *)callerName isVideoCall:(BOOL)isVideoCall completionHandler:(void(^)(NSError *error))completionHandler;
- (void)startCallWithPhoneNumber:(NSString*)phoneNumber calleeName:(NSString *)calleeName isVideoCall:(BOOL)isVideoCall;
- (void)endCall;
- (void)holdCall:(BOOL)hold;

@property (nonatomic, weak) id<CallManagerDelegate> delegate;
@property (nonatomic, strong) NSUUID *currentCall;

@end
