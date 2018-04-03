//
//  SPManager.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactViewController.h"
#import "CallingViewController.h"
#import "HistoryViewController.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CallKit/CallKit.h>
#import "ContactModel.h"
#import "UserModel.h"
#import "SettingViewController.h"

@interface SPManager : NSObject

+ (SPManager *)instance;

@property (strong, nonatomic) NSDictionary *allKeys;
@property (strong, nonatomic) NSMutableArray *listKeys;
@property (strong, nonatomic) NSMutableDictionary *dicSections;

@property (strong, nonatomic) NSMutableArray *arrayCallHistories;
@property (strong, nonatomic) CTCallCenter *callCenter;
@property (strong, nonatomic) CXCallObserver NS_AVAILABLE_IOS(10.0) *callObserver;
@property (strong, nonatomic) NSUserActivity *userActivity;

@property (strong, nonatomic) NSString *deviceToken;
@property (assign, nonatomic) BOOL hasRegisteredToReceivePush;

@property (strong, nonatomic) UserModel *myUser;

- (NSString *)getNumberForCallOut;
- (BOOL)isSystemCall;
- (void)addPrivateContact:(ContactModel *)contactModel;

// Instances
@property (strong, nonatomic) ContactViewController *contactViewController;
@property (strong, nonatomic) CallingViewController *callingViewController;
@property (strong, nonatomic) HistoryViewController *historyViewController;
@property (strong, nonatomic) SettingViewController *settingViewController;



@end
