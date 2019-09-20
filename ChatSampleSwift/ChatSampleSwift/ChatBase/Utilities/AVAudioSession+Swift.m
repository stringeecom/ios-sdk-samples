//
//  AVAudioSession+Swift.m
//  stringeex
//
//  Created by HoangDuoc on 3/30/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

#import "AVAudioSession+Swift.h"

@implementation AVAudioSession (Swift)

- (BOOL)swift_setCategory:(AVAudioSessionCategory)category error:(NSError **)outError {
    return [self setCategory:category error:outError];
}

- (BOOL)swift_setCategory:(AVAudioSessionCategory)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
    return [self setCategory:category withOptions:options error:outError];
}


@end
