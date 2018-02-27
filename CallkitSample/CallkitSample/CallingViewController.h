//
//  CallingViewController.h
//  CallkitSample
//
//  Created by Hoang Duoc on 2/10/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stringee/Stringee.h>
#import "StringeeImplement.h"

@interface CallingViewController : UIViewController<StringeeCallStateDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lbUserId;
@property (weak, nonatomic) IBOutlet UILabel *labelConnecting;
@property (strong, nonatomic) NSString *strUserId;
@property (assign, nonatomic) BOOL isOutgoingCall;
@property (strong, nonatomic) StringeeCall *seCall;

- (IBAction)hangupTapped:(UIButton *)sender;

- (void)startTimer;
- (void)stopTimer;

@end
