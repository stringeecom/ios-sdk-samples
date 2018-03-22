//
//  AppDelegate.m
//  CallkitSample
//
//  Created by Hoang Duoc on 2/1/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "AppDelegate.h"
#import "StringeeImplement.h"
#import <Stringee/Stringee.h>
#import "InstanceManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[StringeeImplement instance] connectToStringeeServer];
    
    // Local push
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // Voip push
    [self voipRegistration];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    [InstanceManager instance].deviceToken = token;
    
    if (![InstanceManager instance].hasRegisteredToReceivePush) {
        // Chú ý: trước khi up lên store thì phải chuyển isProduction = YES
        [[StringeeImplement instance].stringeeClient registerPushForDeviceToken:token isProduction:NO isVoip:YES completionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            if (status) {
                [InstanceManager instance].hasRegisteredToReceivePush = YES;
            }
        }];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    NSLog(@"didReceiveIncomingPushWithPayload %@", payload.dictionaryPayload);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"didReceiveLocalNotification");
    [[StringeeImplement instance] stopRingingWithMessage:@""];
    [[InstanceManager instance].callingViewController answerCallWithAnimation:NO];
}

@end
