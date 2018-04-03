//
//  CallHistoryModel.h
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    IncomingCall,
    OutgoingCall,
    MissCall
} CallState;

@interface CallHistoryModel : NSObject

@property NSString *name;
@property NSString *phone;
@property CallState state; // 0 là gọi đến, 1 là gọi đi, 2 là gọi nhỡ
@property NSString *date;
@property NSString *hour;
@property NSString *duration;
@property BOOL isAppToApp;
@property BOOL isVideoCall;

@end
