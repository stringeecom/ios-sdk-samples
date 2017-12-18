//
//  MainViewController.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tfRoomId;

@property (weak, nonatomic) IBOutlet UIButton *buttonMakeRoom;

@property (weak, nonatomic) IBOutlet UIButton *buttonJoinRoom;

- (IBAction)makeRoomTapped:(UIButton *)sender;
- (IBAction)joinRoomTapped:(UIButton *)sender;

@end
