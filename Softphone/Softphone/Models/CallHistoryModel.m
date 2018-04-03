//
//  CallHistoryModel.m
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "CallHistoryModel.h"

@implementation CallHistoryModel

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_phone forKey:@"phone"];
    [coder encodeObject:_date forKey:@"date"];
    [coder encodeObject:_hour forKey:@"hour"];
    [coder encodeObject:_duration forKey:@"duration"];
    
    [coder encodeInteger:_state forKey:@"state"];
    [coder encodeBool:_isAppToApp forKey:@"isAppToApp"];
    [coder encodeBool:_isVideoCall forKey:@"isVideoCall"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        _name = [coder decodeObjectForKey:@"name"];
        _phone = [coder decodeObjectForKey:@"phone"];
        _date = [coder decodeObjectForKey:@"date"];
        _hour = [coder decodeObjectForKey:@"hour"];
        _duration = [coder decodeObjectForKey:@"duration"];

        _state = [coder decodeIntegerForKey:@"state"];
        _isAppToApp = [coder decodeBoolForKey:@"isAppToApp"];
        _isVideoCall = [coder decodeBoolForKey:@"isVideoCall"];
    }
    return self;
}



@end
