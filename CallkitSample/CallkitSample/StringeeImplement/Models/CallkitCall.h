//
//  CallkitCall.h
//  CallkitSample
//
//  Created by HoangDuoc on 7/14/22.
//  Copyright © 2022 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stringee/Stringee.h>
#import <CallKit/CallKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallkitCall : NSObject

@property (nonatomic, assign) int serial;
@property (nonatomic) NSString *callId;
@property (nonatomic) StringeeCall *stringeeCall;
@property (nonatomic) NSUUID *uuid;
@property (nonatomic, nullable) CXAnswerCallAction *answerAction;

@property (nonatomic, assign) BOOL answered;
@property (nonatomic, assign) BOOL rejected;
@property (nonatomic, assign) BOOL audioIsActived;
@property (nonatomic, assign) BOOL isIncoming;

- (instancetype)initWithIncomingState:(BOOL)isIncoming startTimer:(BOOL)startTimer;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
