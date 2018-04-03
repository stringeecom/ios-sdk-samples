//
//  AppDelegate.h
//  Softphone
//
//  Created by Hoang Duoc on 3/2/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>
#import <Intents/Intents.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

