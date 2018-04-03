//
//  SettingViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "SettingViewController.h"
#import "UserInfoTableViewCell.h"
#import "NumberTableViewCell.h"
#import "Constants.h"
#import "Utils.h"
#import "LoginViewController.h"
#import "StringeeImplement.h"
#import "SPManager.h"
#import "CalloutNumberModel.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SPManager instance].settingViewController = self;
    
    [self.tblSetting registerNib:[UINib nibWithNibName:@"UserInfoTableViewCell" bundle:nil] forCellReuseIdentifier:@"userCell"];
    [self.tblSetting registerNib:[UINib nibWithNibName:@"NumberTableViewCell" bundle:nil] forCellReuseIdentifier:@"numberCell"];
    [self.tblSetting registerClass:UITableViewCell.self forCellReuseIdentifier:@"logoutCell"];
    
    self.tblSetting.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUpdateNumber)
                                                 name:@"Update_Number"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleUpdateNumber {
    [self.tblSetting reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return [SPManager instance].myUser.calloutNumbers.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        UserInfoTableViewCell *userCell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
        [userCell configureCell];
        return userCell;
    } else if (indexPath.section == 1) {
        NumberTableViewCell *numberCell = [tableView dequeueReusableCellWithIdentifier:@"numberCell" forIndexPath:indexPath];
        CalloutNumberModel *calloutNumber = [[SPManager instance].myUser.calloutNumbers objectAtIndex:indexPath.row];
        [numberCell configureCellWithCallOutNumber:calloutNumber calloutNumberIndex:(int)indexPath.row];
        
        return numberCell;
    } else {
        UITableViewCell *logoutCell = [tableView dequeueReusableCellWithIdentifier:@"logoutCell" forIndexPath:indexPath];
        logoutCell.textLabel.text = @"Đăng xuất";
        logoutCell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        logoutCell.textLabel.textColor = [UIColor redColor];
        logoutCell.textLabel.textAlignment = NSTextAlignmentCenter;
        return logoutCell;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 80;
    }
    
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 20;
    } else if (section == 2) {
        return 40;
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCR_WIDTH, 40)];
    headerView.backgroundColor = [Utils colorWithHexString:HEADER_COLOR];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        
        UIAlertControllerStyle style;
        
        if (IS_IPHONE) {
            // iphone
            style = UIAlertControllerStyleActionSheet;
        } else {
            // ipad + tv...
            style = UIAlertControllerStyleAlert;
        }
        
        UIAlertController *confirmAlert = [UIAlertController
                                           alertControllerWithTitle:nil
                                           message:@"Bạn có chắc chắn muốn thoát"
                                           preferredStyle:style];
        UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:@"Đăng xuất" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            //logout
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"myUser"];
            [prefs removeObjectForKey:@"call_history"];
            [prefs synchronize];
            
            [[SPManager instance].arrayCallHistories removeAllObjects];
            [[SPManager instance].listKeys removeAllObjects];
            [[SPManager instance].dicSections removeAllObjects];
            [SPManager instance].myUser = nil;
            
            [Utils showProgressViewWithString:@"" inView:self.view];
            
            [[StringeeImplement instance].stringeeClient unregisterPushForDeviceToken:[SPManager instance].deviceToken completionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"%@", message);
                [[StringeeImplement instance].stringeeClient disconnect];
                [Utils hideProgressViewInView:self.view];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SPManager instance].hasRegisteredToReceivePush = NO;
                    
                    LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
                    [UIApplication sharedApplication].keyWindow.rootViewController = loginVC;
                });
            }];
        }];
        
        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil];
        [confirmAlert addAction:logoutAction];
        [confirmAlert addAction:cancelAction];
        
        [self.navigationController presentViewController:confirmAlert animated:YES completion:nil];
    }
}

@end
