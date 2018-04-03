//
//  HTTPClient.m
//  Softphone
//
//  Created by Hoang Duoc on 3/15/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "HTTPClient.h"

static HTTPClient *httpClient = nil;
#define baseUrl @"https://v1.stringee.com/softphone-apis/public_html/account/"

@implementation HTTPClient {
   AFHTTPSessionManager * manager;
}

// MARK: - Init
+ (HTTPClient *)instance {
    @synchronized(self) {
        if (httpClient == nil) {
            httpClient = [[self alloc] init];
        }
    }
    return httpClient;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration * configure = [NSURLSessionConfiguration defaultSessionConfiguration];
        configure.timeoutIntervalForRequest = 30;
        manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configure];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    return self;
}

- (void)POST:(NSString *)strUrl parameters:(NSDictionary<NSString *, id> *)parameters completionHandler:(void(^)(BOOL status, int code, id responseObject))completionHandler {
    
    NSString *targetUrl = [baseUrl stringByAppendingString:strUrl];

    [manager POST:targetUrl parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary * data = (NSDictionary *)responseObject;
        NSNumber *status = [data objectForKey:@"status"];
        if (status.intValue == 200) {
            // Thành công
            completionHandler(YES, 1, data);
        } else {
            // Thất bại
            NSString *message = [data objectForKey:@"message"];
            completionHandler(NO, 0, message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // Request thất bại
        completionHandler(NO, 0, error.localizedDescription);
    }];
}


@end
