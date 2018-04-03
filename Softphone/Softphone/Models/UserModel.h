//
//  UserModel.h
//  Softphone
//
//  Created by Hoang Duoc on 3/20/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalloutNumberModel.h"

@interface UserModel : NSObject

@property NSString *phone;
@property NSString *token;
@property NSString *accessToken;
@property long long expireTime;
@property NSArray *calloutNumbers;

- (instancetype)initWithData:(NSDictionary *)data;

@end
