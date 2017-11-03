//
//  MainViewController.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tfUserID;
@property (weak, nonatomic) IBOutlet UISwitch *switchVideoCall;
@property (weak, nonatomic) IBOutlet UIButton *buttonCall;

- (IBAction)callTapped:(UIButton *)sender;


@end
