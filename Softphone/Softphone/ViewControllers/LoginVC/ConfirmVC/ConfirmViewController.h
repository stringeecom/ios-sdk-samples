//
//  ConfirmViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 3/16/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Softphone-Swift.h"

@protocol PinCodeTextFieldDelegate;

@interface ConfirmViewController : UIViewController<PinCodeTextFieldDelegate>

@property (weak, nonatomic) IBOutlet PinCodeTextField *tfPinCode;

@property (strong, nonatomic) NSString *phoneNumber;

@property (weak, nonatomic) IBOutlet UILabel *lbDescription;

@end
