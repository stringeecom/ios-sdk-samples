//
//  InstanceManager.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
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
