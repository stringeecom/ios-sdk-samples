//
//  AVAudioSession+Swift.h
//  stringeex
//
//  Created by HoangDuoc on 3/30/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (Swift)

- (BOOL)swift_setCategory:(AVAudioSessionCategory)category error:(NSError **)outError NS_SWIFT_NAME(setCategory(_:));
- (BOOL)swift_setCategory:(AVAudioSessionCategory)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError NS_SWIFT_NAME(setCategory(_:options:));

@end

NS_ASSUME_NONNULL_END
