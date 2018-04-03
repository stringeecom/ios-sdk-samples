//
//  CalloutNumberModel.h
//  Softphone
//
//  Created by Hoang Duoc on 3/21/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalloutNumberModel : NSObject

@property NSString *phone;
@property BOOL isEnable;

- (instancetype)initWithPhone:(NSString *)phone;

@end
