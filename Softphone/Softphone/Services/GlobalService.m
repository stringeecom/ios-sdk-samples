//
//  GlobalService.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "GlobalService.h"
#import "HTTPClient.h"

@implementation GlobalService

+ (void)loginWithPhoneNumber:(NSString *)phone completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler {
    NSDictionary *params = @{
                             @"phone" : phone
                             };
    [[HTTPClient instance] POST:@"login" parameters:params completionHandler:^(BOOL status, int code, id responseObject) {
        if (status) {
            NSDictionary *data = [((NSDictionary *)responseObject) objectForKey:@"data"];
            completionHandler(status, code, data);
        } else {
            completionHandler(status, code, (NSString *)responseObject);
        }
    }];
}

+ (void)comfirmWithPhoneNumber:(NSString *)phone code:(NSString *)code completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler {
    NSDictionary *params = @{
                             @"phone" : phone,
                             @"code" : code
                             };
    [[HTTPClient instance] POST:@"confirm" parameters:params completionHandler:^(BOOL status, int code, id responseObject) {
        if (status) {
            NSDictionary *data = [((NSDictionary *)responseObject) objectForKey:@"data"];
            completionHandler(status, code, data);
        } else {
            completionHandler(status, code, (NSString *)responseObject);
        }
    }];
}

+ (void)checkPhoneBookExistedWithPhoneBook:(NSArray *)phoneBook token:(NSString *)token completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler {
    NSDictionary *params = @{
                             @"token" : token,
                             @"phonebook" : phoneBook
                             };
    [[HTTPClient instance] POST:@"checkphonebookexisted" parameters:params completionHandler:^(BOOL status, int code, id responseObject) {
        if (status) {
            NSDictionary *data = [((NSDictionary *)responseObject) objectForKey:@"data"];
            completionHandler(status, code, data);
        } else {
            completionHandler(status, code, (NSString *)responseObject);
        }
    }];
}

+ (void)getAccessTokenWithToken:(NSString *)token completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler {
    NSDictionary *params = @{
                             @"token" : token
                             };
    [[HTTPClient instance] POST:@"getaccesstoken" parameters:params completionHandler:^(BOOL status, int code, id responseObject) {
        if (status) {
            NSDictionary *data = [((NSDictionary *)responseObject) objectForKey:@"data"];
            completionHandler(status, code, data);
        } else {
            completionHandler(status, code, (NSString *)responseObject);
        }
    }];
}


@end
