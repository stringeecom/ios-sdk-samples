//
//  STEWeakTimerTarget.m
//  Stringee
//
//  Created by HoangDuoc on 4/25/20.
//  Copyright © 2020 Hoang Duoc. All rights reserved.
//

#import "WeakTimerTarget.h"

@implementation WeakTimerTarget {
    __weak id target;
    SEL selector;
}

- (instancetype)initWithTarget:(id)tar selector:(SEL)sel
{
    self = [super init];
    if (self) {
        target = tar;
        selector = sel;
    }
    return self;
}

- (void)timerDidFire:(NSTimer *)timer {
    if(target) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:selector withObject:timer];
        #pragma clang diagnostic pop
    } else {
        [timer invalidate];
    }
}

@end
