//
//  CallkitCall.m
//  CallkitSample
//
//  Created by HoangDuoc on 7/14/22.
//  Copyright © 2022 Hoang Duoc. All rights reserved.
//

#import "CallkitCall.h"
#import "WeakTimerTarget.h"
#import "CallManager.h"

@implementation CallkitCall {
    int counter;
    NSTimer *timeoutTimer;
}

- (instancetype)initWithIncomingState:(BOOL)isIncoming startTimer:(BOOL)startTimer {
    self = [super init];
    if (self) {
        self.isIncoming = isIncoming;
        if (startTimer) {
            [self startTimer];
        }
    }
    return self;
}

- (void)handleCallTimeOut {
    counter += 2;
    if (counter >= 28) {
        [self stopTimer];
        if (!self.answered && !self.rejected) {
            [[CallManager instance] endCall];
        }
    }
}

- (void)startTimer {
    if (timeoutTimer != nil) {
        return;
    }
    
    WeakTimerTarget *target = [[WeakTimerTarget alloc] initWithTarget:self selector:@selector(handleCallTimeOut)];
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:target selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
    [timeoutTimer fire];
}

- (void)stopTimer {
    [timeoutTimer invalidate];
    timeoutTimer = nil;
}

- (void)clean {
    [self stopTimer];
}

- (void)dealloc {
    [self stopTimer];
}


@end
