//
//  InstanceManager.m
//  StringeeVoiceCallSDK
//
//  Created by Hoang Duoc on 9/28/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "InstanceManager.h"

@implementation InstanceManager

static InstanceManager *sharedMyManager = nil;

+ (InstanceManager *)instance {
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
    }
    return self;
}

@end
