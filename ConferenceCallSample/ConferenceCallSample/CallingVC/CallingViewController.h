//
//  CallViewController.h
//  TestStringeeWebRTC
//
//  Created by Hoang Duoc on 9/21/17.
//  Copyright © 2017 Dau Ngoc Huy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stringee/Stringee.h>

@interface CallingViewController : UIViewController<StringeeRoomDelegate, StringeeRemoteViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageQuality;
@property (weak, nonatomic) IBOutlet UIButton *buttonMute;
@property (weak, nonatomic) IBOutlet UIButton *buttonSpeaker;
@property (weak, nonatomic) IBOutlet UIButton *buttonCamera;
@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchCamera;
@property (weak, nonatomic) IBOutlet UILabel *labelRoomId;
@property (weak, nonatomic) IBOutlet UIView *containRemoteView1;
@property (weak, nonatomic) IBOutlet UIView *containRemoteView2;
@property (weak, nonatomic) IBOutlet UIView *containRemoteView3;
@property (weak, nonatomic) IBOutlet UIView *containRemoteView4;

- (IBAction)switchCameraTapped:(UIButton *)sender;
- (IBAction)muteTapped:(UIButton *)sender;
- (IBAction)speakerTapped:(UIButton *)sender;
- (IBAction)cameraTapped:(UIButton *)sender;
- (IBAction)endCallTapped:(UIButton *)sender;


@property(strong, nonatomic) StringeeRoom *stringeeRoom;
@property(assign, nonatomic) BOOL isMakeRoom; // isMakeRoom = YES -> Make Room, isMakeRoom = NO -> Join Room
@property(assign, nonatomic) long long roomId;

@end
