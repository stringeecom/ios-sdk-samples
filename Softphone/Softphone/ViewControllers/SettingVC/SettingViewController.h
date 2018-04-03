//
//  SettingViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 3/7/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tblSetting;

@end
