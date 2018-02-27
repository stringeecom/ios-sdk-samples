//
//  ViewController.h
//  CallkitSample
//
//  Created by Hoang Duoc on 2/1/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tfUserId;
@property (weak, nonatomic) IBOutlet UIButton *btCall;



- (IBAction)callTapped:(UIButton *)sender;

@end

