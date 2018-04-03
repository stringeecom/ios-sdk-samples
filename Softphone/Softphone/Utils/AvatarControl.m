//
//  AvatarControl.m
//  Biin
//
//  Created by Hoang Duoc on 2/23/17.
//  Copyright © 2017 Dau Ngoc Huy. All rights reserved.
//

#import "AvatarControl.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Utils.h"

@implementation AvatarControl

- (id) init {
    self = [super init];
    if (self != nil) {
        self.dic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

static AvatarControl * _instance;

+ (AvatarControl*)instance {
    @synchronized(self) {
        if (!_instance){
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (UIImage *) getAvatar:(NSString *)str{
    UIImage * avatar = self.dic[str];
    if (avatar) {
        return avatar;
    }
    else{
        avatar = [Utils getImageAvatarLetter:CGRectMake(0, 0, 60, 60) withString:str withColor:nil];
        self.dic[str] = avatar;
        return avatar;
    }
}

@end
