//
//  Contact.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactModel : NSObject

@property NSString *name;
@property NSString *phone_display;
@property NSString *phone_call;
@property BOOL isExistence;

- (instancetype)initWithName:(NSString *)name phone:(NSString *)phone;

@end
