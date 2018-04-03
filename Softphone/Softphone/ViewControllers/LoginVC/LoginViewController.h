//
//  LoginViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalService.h"

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tfPhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *btLogin;

- (IBAction)loginTapped:(UIButton *)sender;
@end
