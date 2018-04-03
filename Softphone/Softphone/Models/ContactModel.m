//
//  Contact.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "ContactModel.h"
#import "Utils.h"

@implementation ContactModel

- (instancetype)initWithName:(NSString *)name phone:(NSString *)phone {
    self = [super init];
    if (self) {
        _name = name;
        _phone_display = phone;
        _phone_call = [Utils getPhoneForCall:_phone_display];
        _isExistence = NO;
    }
    return self;
}

@end
