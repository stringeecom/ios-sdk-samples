//
//  UserModel.m
//  Softphone
//
//  Created by Hoang Duoc on 3/20/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

- (instancetype)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _phone = (data[@"phone"] != nil && data[@"phone"] != [NSNull null]) ? (NSString *)data[@"phone"] : @"";
        _token = (data[@"token"] != nil && data[@"token"] != [NSNull null]) ? (NSString *)data[@"token"] : @"";
        _accessToken = (data[@"access_token"] != nil && data[@"access_token"] != [NSNull null]) ? (NSString *)data[@"access_token"] : @"";
        _expireTime = (data[@"expire_time"] != nil && data[@"expire_time"] != [NSNull null]) ? ((NSNumber *)data[@"expire_time"]).longLongValue : 0;
        
        NSArray *phones = (data[@"callOutNumber"] != nil && data[@"callOutNumber"] != [NSNull null]) ? (NSArray *)data[@"callOutNumber"] : [[NSArray alloc] init];
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for (NSString *phone in phones) {
            CalloutNumberModel *calloutNumber = [[CalloutNumberModel alloc] initWithPhone:phone];
            [tempArray addObject:calloutNumber];
        }
        _calloutNumbers = tempArray;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:_phone forKey:@"phone"];
    [coder encodeObject:_token forKey:@"token"];
    [coder encodeObject:_accessToken forKey:@"accessToken"];
    [coder encodeObject:[NSNumber numberWithLongLong:_expireTime] forKey:@"expireTime"];
    [coder encodeObject:_calloutNumbers forKey:@"calloutNumbers"];

}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        _phone = [coder decodeObjectForKey:@"phone"];
        _token = [coder decodeObjectForKey:@"token"];
        _accessToken = [coder decodeObjectForKey:@"accessToken"];
        _expireTime = ((NSNumber *)[coder decodeObjectForKey:@"expireTime"]).longLongValue;
        _calloutNumbers = (NSArray *)[coder decodeObjectForKey:@"calloutNumbers"];
    }
    return self;
}

@end
