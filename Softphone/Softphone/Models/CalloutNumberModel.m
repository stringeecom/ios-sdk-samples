//
//  CalloutNumberModel.m
//  Softphone
//
//  Created by Hoang Duoc on 3/21/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "CalloutNumberModel.h"

@implementation CalloutNumberModel

- (instancetype)initWithPhone:(NSString *)phone {
    self = [super init];
    if (self) {
        _phone = phone;
        _isEnable = YES;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:_phone forKey:@"phone"];
    [coder encodeBool:_isEnable forKey:@"isEnable"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        _phone = [coder decodeObjectForKey:@"phone"];
        _isEnable = [coder decodeBoolForKey:@"isEnable"];
    }
    return self;
}

@end
