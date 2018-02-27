//
//  AppDelegate.h
//  CallkitSample
//
//  Created by Hoang Duoc on 2/1/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

