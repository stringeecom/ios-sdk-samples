//
//  AppDelegate.m
//  Softphone
//
//  Created by Hoang Duoc on 3/2/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "Utils.h"
#import "Constants.h"
#import "StringeeImplement.h"
#import "SPManager.h"
#import <IQKeyboardManager/IQKeyboardManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self configureApp];
    
    // Đăng kí nhận local push
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // Đăng kí nhận voip push
    [self voipRegistration];
        
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // Kiểm tra trạng thái đăng nhập
    if ([SPManager instance].myUser.phone.length) {
        MainTabBarController *mainTabbarVC = [[MainTabBarController alloc] init];
        window.rootViewController = mainTabbarVC;
    } else {
        LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        window.rootViewController = loginVC;
    }
    
    self.window = window;
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {

}


- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)configureApp {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [UINavigationBar appearance].translucent = NO;
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [UINavigationBar appearance].barTintColor = [Utils colorWithHexString:PRIMARY_COLOR];
    [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    
    [IQKeyboardManager sharedManager].enable = YES;
}

- (void) voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    NSString *token = [[credentials.token description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"**************** Token - Voip push: %@", token);
    [SPManager instance].deviceToken = token;
    
    if (![SPManager instance].hasRegisteredToReceivePush) {
        [[StringeeImplement instance].stringeeClient registerPushForDeviceToken:token isProduction:isProductionMode isVoip:YES completionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            if (status) {
                [SPManager instance].hasRegisteredToReceivePush = YES;
            }
        }];
    }
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * _Nullable))restorationHandler {
    
    [SPManager instance].userActivity = userActivity;
    
    if ([StringeeImplement instance].stringeeClient.hasConnected) {
        [[StringeeImplement instance] createCallFollowUserActivity:userActivity];
    }
    
    return YES;
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    NSLog(@"didReceiveIncomingPushWithPayload %@", payload.dictionaryPayload);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"didReceiveLocalNotification");
    [[StringeeImplement instance] stopRingingWithMessage:@""];
    [[SPManager instance].callingViewController answerCallWithAnimation:NO];
}
@end
