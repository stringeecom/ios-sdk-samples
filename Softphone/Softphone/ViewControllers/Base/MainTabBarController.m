//
//  MainTabBarController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "MainTabBarController.h"
#import "ContactViewController.h"
#import "CallPadViewController.h"
#import "HistoryViewController.h"
#import "SettingViewController.h"
#import "SPManager.h"
#import "StringeeImplement.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController {
    int previousIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    [[StringeeImplement instance] connectToStringeeServer];
    [self configureTabbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)configureTabbar {
    
    HistoryViewController *historyVC = [[HistoryViewController alloc] initWithNibName:@"HistoryViewController" bundle:nil];
    historyVC.navigationItem.title = @"Lịch sử";
    UINavigationController *historyNavi = [[UINavigationController alloc] initWithRootViewController:historyVC];
    UITabBarItem * historyItem = [[UITabBarItem alloc] initWithTitle:@"Lịch sử" image:[[UIImage imageNamed:@"tabbar_history_deselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:@"tabbar_history_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    historyNavi.tabBarItem = historyItem;
    
    ContactViewController *contactVC = [[ContactViewController alloc] initWithNibName:@"ContactViewController" bundle:nil];
    contactVC.title = @"Danh bạ";
    UINavigationController *contactNavi = [[UINavigationController alloc] initWithRootViewController:contactVC];
    UITabBarItem * contactItem = [[UITabBarItem alloc] initWithTitle:@"Danh bạ" image:[[UIImage imageNamed:@"tabbar_contact_deselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:@"tabbar_contact_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    contactNavi.tabBarItem = contactItem;
    
    CallPadViewController *callPadVC = [[CallPadViewController alloc] initWithNibName:@"CallPadViewController" bundle:nil];
    UITabBarItem * callPadItem = [[UITabBarItem alloc] initWithTitle:@"Bàn phím" image:[[UIImage imageNamed:@"tabbar_call_deselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:@"tabbar_call_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    callPadVC.tabBarItem = callPadItem;
    
    SettingViewController *settingVC = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    settingVC.title = @"Cài đặt";
    UINavigationController *settingNavi = [[UINavigationController alloc] initWithRootViewController:settingVC];
    UITabBarItem * settingItem = [[UITabBarItem alloc] initWithTitle:@"Cài đặt" image:[[UIImage imageNamed:@"tabbar_setting_deselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:@"tabbar_setting_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    settingNavi.tabBarItem = settingItem;
    
    self.viewControllers = @[historyNavi, contactNavi, callPadVC, settingNavi];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if (previousIndex == 1 && self.selectedIndex != previousIndex) {
        [[SPManager instance].contactViewController hideSearchController];
    }
    previousIndex = (int)self.selectedIndex;
}




@end
