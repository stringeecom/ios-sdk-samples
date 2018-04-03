//
//  HTTPClient.h
//  Softphone
//
//  Created by Hoang Duoc on 3/15/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface HTTPClient : NSObject

+ (HTTPClient *)instance;

- (void)POST:(NSString *)strUrl parameters:(NSDictionary<NSString *, id> *)parameters completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler;

@end
