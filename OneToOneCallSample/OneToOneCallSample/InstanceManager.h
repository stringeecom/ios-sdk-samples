//
//  InstanceManager.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"
#import "CallingViewController.h"

@interface InstanceManager : NSObject

+ (InstanceManager *)instance;

@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic) CallingViewController *callingViewController;

@end
