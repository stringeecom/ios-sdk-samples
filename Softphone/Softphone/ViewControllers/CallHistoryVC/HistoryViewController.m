//
//  HistoryViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "HistoryViewController.h"
#import "SPManager.h"
#import "StringeeImplement.h"
#import "HistoryTableViewCell.h"
#import "Constants.h"
#import "Utils.h"
#import "CallHistoryModel.h"

@interface HistoryViewController ()

@end

@implementation HistoryViewController {
    BOOL userHasSwiped;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [SPManager instance].historyViewController = self;
    
    [self.tblHistory registerNib:[UINib nibWithNibName:@"HistoryTableViewCell" bundle:nil] forCellReuseIdentifier:@"historyCell"];
    self.tblHistory.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if ([StringeeImplement instance].stringeeClient.hasConnected) {
        self.navigationItem.title = [StringeeImplement instance].stringeeClient.userId;
    } else {
        self.navigationItem.title = @"Connecting...";
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUpdateCallHistory)
                                                 name:@"Update_Call_History"
                                               object:nil];

    [self checkReloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.editButtonItem.title = @"Sửa";
    [self setEditing:NO animated:YES];
    [self.tblHistory setEditing:NO animated:YES];
}

// MARK:- Private method

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    NSLog(@"setEditing");

    [super setEditing:editing animated:animated];
    
    if (editing) {
        self.editButtonItem.title = @"Xong";
        [self.tblHistory setEditing:YES animated:YES];
        
        if (!userHasSwiped) {
            UIBarButtonItem *bbtDelete = [[UIBarButtonItem alloc] initWithTitle:@"Xóa" style:UIBarButtonItemStylePlain target:self action:@selector(deleteTapped)];
            self.navigationItem.leftBarButtonItem = bbtDelete;
        }
    } else {
        self.editButtonItem.title = @"Sửa";
        [self.tblHistory setEditing:NO animated:YES];
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)deleteTapped {
    
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
                                       message:nil
                                       preferredStyle:style];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Xóa tất cả lịch sử" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // logout
        NSLog(@"Delete all");
        [[SPManager instance].arrayCallHistories removeAllObjects];
        [self checkReloadData];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil];
    [confirmAlert addAction:deleteAction];
    [confirmAlert addAction:cancelAction];
    
    [self.navigationController presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)handleUpdateCallHistory {
    [self checkReloadData];
}

- (void)checkReloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SPManager instance].arrayCallHistories.count) {
            self.tblHistory.scrollEnabled = YES;
            self.tblHistory.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
            self.editButtonItem.title = @"Sửa";
            self.navigationItem.rightBarButtonItem = [self editButtonItem];
        } else {
            self.tblHistory.scrollEnabled = NO;
            self.tblHistory.tableFooterView = [self getNoCallHistoryView];
            self.navigationItem.rightBarButtonItem = nil;
            self.navigationItem.leftBarButtonItem = nil;
        }
        [self.tblHistory reloadData];
    });
}

- (UIView *)getNoCallHistoryView {
    
    UIView * noContactView = [[UIView alloc] init];
    
    UILabel * content = [[UILabel alloc] init];
    
    content.font = [UIFont systemFontOfSize:25.0];
    content.textAlignment = NSTextAlignmentCenter;
    content.textColor = [UIColor lightGrayColor];
    content.text = @"Không có lịch sử";
    [noContactView addSubview:content];
    
    CGSize size = CGSizeMake(SCR_WIDTH, SCR_HEIGHT - 64 - 44 - 50);
    
    noContactView.frame = CGRectMake(0, 0, size.width, size.height);
    content.frame = CGRectMake(0, - 50 /2.0, size.width, size.height);
    
    return noContactView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [SPManager instance].arrayCallHistories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HistoryTableViewCell *historyCell = [tableView dequeueReusableCellWithIdentifier:@"historyCell" forIndexPath:indexPath];
    CallHistoryModel *callHistory = [[SPManager instance].arrayCallHistories objectAtIndex:indexPath.row];
    [historyCell configureCellWithCallHistory:callHistory];
    
    return historyCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CallHistoryModel *historyModel = [[SPManager instance].arrayCallHistories objectAtIndex:indexPath.row];
    
    if ([StringeeImplement instance].stringeeClient.hasConnected && ![[SPManager instance] isSystemCall]) {
        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:nil];
        callingVC.isIncomingCall = NO;
        if (historyModel.name.length) {
            callingVC.username = historyModel.name;
        } else {
            callingVC.username = historyModel.phone;
        }
        callingVC.from = [[SPManager instance] getNumberForCallOut];
        callingVC.to = [Utils getPhoneForCall:historyModel.phone];
        callingVC.isAppToApp = historyModel.isAppToApp;
        callingVC.isVideoCall = historyModel.isVideoCall;
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    } else {
        [Utils showToastWithString:@"Không có kết nối" withView:self.view];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    userHasSwiped = YES;
    [self setEditing:YES animated:YES];
    self.editButtonItem.title = @"Xong";
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    userHasSwiped = NO;
    [self setEditing:NO animated:YES];
    self.editButtonItem.title = @"Sửa";

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"Delete");
        
        // Xóa dữ liệu
        [[SPManager instance].arrayCallHistories removeObjectAtIndex:indexPath.row];
        
        // Xóa cell
        if ([SPManager instance].arrayCallHistories.count) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        } else {
            [self checkReloadData];
        }
    }
}



@end
