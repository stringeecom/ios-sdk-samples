//
//  STEWeakTimerTarget.h
//  Stringee
//
//  Created by HoangDuoc on 4/25/20.
//  Copyright © 2020 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WeakTimerTarget : NSObject

- (instancetype)initWithTarget:(id)tar selector:(SEL)sel;

@end

NS_ASSUME_NONNULL_END
