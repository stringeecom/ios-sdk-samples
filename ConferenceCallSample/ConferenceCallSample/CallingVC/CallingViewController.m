//
//  CallViewController.m
//  TestStringeeWebRTC
//
//  Created by Hoang Duoc on 9/21/17.
//  Copyright © 2017 Dau Ngoc Huy. All rights reserved.
//

#import "CallingViewController.h"
#import "InstanceManager.h"
#import "StringeeImplement.h"
#import <Stringee/Stringee.h>

static int TIME_WINDOW = 2;

@interface CallingViewController ()

@end

@implementation CallingViewController {
    BOOL cameraIsOff;
    BOOL isMute;
    BOOL isSpeaker;
    NSTimer *statsTimer;
    BOOL hasCheckedStats;
    
    // Stats report
    long long audioBw;
    double audioPLRatio;
    long long prevAudioPacketLost;
    long long prevAudioPacketReceived;
    long long prevAudioTimeStamp;
    long long prevAudioBytes;
    
    // Stream
    StringeeRoomStream *localStream;
    NSMutableArray *arrayRemoteStreams;
    int viewIndex;
}

// MARK: - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [InstanceManager instance].callingViewController = self;
    arrayRemoteStreams = [[NSMutableArray alloc] init];
    viewIndex = 1;
    
    // Configure Audio Session
    StringeeAudioManager * audioManager = [StringeeAudioManager instance];
    [audioManager audioSessionSetActive:YES error:nil];
    
    self.buttonSpeaker.enabled = NO;
}

-(void) viewWillAppear:(BOOL)animated {
    

    
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isMakeRoom) {
        self.stringeeRoom = [[StringeeRoom alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient];
        self.stringeeRoom.delegate = self;
        [self.stringeeRoom makeRoomWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            if (status) {
                // Sucess
                self.labelRoomId.text = [NSString stringWithFormat:@"%lld", self.stringeeRoom.roomId];
            } else {
                // Fail
                [self clearAndEnd];
            }
        }];
    } else {
        self.stringeeRoom = [[StringeeRoom alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient];
        self.stringeeRoom.delegate = self;
        [self.stringeeRoom joinRoomWithRoomId:self.roomId completionHandler:^(BOOL status, int code, NSString *message) {
            if (status) {
                // Success
                self.labelRoomId.text = [NSString stringWithFormat:@"%lld", self.stringeeRoom.roomId];
            } else {
                // Fail
                [self clearAndEnd];
            }
        }];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Bắt sự kiện rotate của device và thay đổi orientation của local video
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (localStream) {
        [localStream autoOrientationOfLocalVideoViewWithSize:size withTransitionCoordinator:coordinator];
        
        // Change frame of localVideoView
        [localStream.localVideoView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    }
}

// MARK: - Stringee Room Delegate
- (void)didRoomConnect:(StringeeRoom *)stringeeRoom streams:(NSArray<StringeeRoomStream *> *)streams {
    NSLog(@"Đã kết nối tới room");
    StringeeRoomStreamConfig * config = [[StringeeRoomStreamConfig alloc] init];
    config.streamVideoResolution = VideoResolution_Normal;
    localStream = [[StringeeRoomStream alloc] initLocalStreamWithConfig:config];
    localStream.localVideoView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self.view insertSubview:localStream.localVideoView atIndex:0];
    
    [self.stringeeRoom publish:localStream];
    
    for (StringeeRoomStream * stream in streams) {
        [self.stringeeRoom subscribe:stream];
    }
    
}

- (void)didRoomError:(StringeeRoom *)stringeeRoom code:(int)code message:(NSString *)message {
    NSLog(@"Kết nối tới room lỗi");
    [self clearAndEnd];
}

- (void)didRoomDisConnect:(StringeeRoom *)stringeeRoom {
    NSLog(@"Đã ngắt kết nối tới room");
}

// Publish and unpublish
- (void)didStreamPublish:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    NSLog(@"Publish local stream thành công - streamId: %@", stream.streamId);
//    isSpeaker = YES;
//    [[StringeeAudioManager instance] setLoudspeaker:YES];
}

- (void)didStreamPublishError:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream error:(NSString *)error {
    NSLog(@"%@", error);
}

- (void)didStreamUnPublish:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    NSLog(@"unPublish local stream thành công - streamId: %@", stream.streamId);
}

- (void)didStreamUnPublishError:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream error:(NSString *)error {
    NSLog(@"%@", error);
}

- (void)didStreamAdd:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    [self.stringeeRoom subscribe:stream];
}

- (void)didStreamSubscribe:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    NSLog(@"Đã subscribe stream - streamId: %@", stream.streamId);
    [arrayRemoteStreams addObject:stream];
    stream.remoteVideoView.delegate = self;
    
    switch (viewIndex) {
        case 1:
            [stream.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView1.bounds.size.width, self.containRemoteView1.bounds.size.height)];
            self.containRemoteView1.backgroundColor = [UIColor blackColor];
            [self.containRemoteView1 addSubview:stream.remoteVideoView];
            break;
        case 2:
            [stream.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView2.bounds.size.width, self.containRemoteView2.bounds.size.height)];
            self.containRemoteView2.backgroundColor = [UIColor blackColor];
            [self.containRemoteView2 addSubview:stream.remoteVideoView];
            break;
        case 3:
            [stream.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView3.bounds.size.width, self.containRemoteView3.bounds.size.height)];
            self.containRemoteView3.backgroundColor = [UIColor blackColor];
            [self.containRemoteView3 addSubview:stream.remoteVideoView];
            break;
        case 4:
            [stream.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView4.bounds.size.width, self.containRemoteView4.bounds.size.height)];
            self.containRemoteView4.backgroundColor = [UIColor blackColor];
            [self.containRemoteView4 addSubview:stream.remoteVideoView];
            break;
        default:
            [stream.remoteVideoView setFrame:CGRectMake(0, 0, self.containRemoteView4.bounds.size.width, self.containRemoteView4.bounds.size.height)];
            stream.remoteVideoView.center = self.view.center;
            [self.view addSubview:stream.remoteVideoView];
            break;
    }
    
    viewIndex += 1;
    
    if (!hasCheckedStats) {
        [self beginCheck];
    }
    
    // By default, stringeesdk will output audio to the built-in speaker. You need to change if you want it out loud
    if (!self.buttonSpeaker.enabled) {
        self.buttonSpeaker.enabled = YES;
//        isSpeaker = YES;
//        [[StringeeAudioManager instance] setLoudspeaker:YES];
    }
}



- (void)didStreamSubscribeError:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream error:(NSString *)error {
    NSLog(@"%@", error);
}


- (void)didStreamUnSubscribe:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    NSLog(@"Đã unsubscribe stream - streamId: %@", stream.streamId);
    
    // Remove render view
    if (stream.remoteVideoView.superview) {
        [stream.remoteVideoView removeFromSuperview];
    }
    

}

- (void)didStreamUnSubscribeError:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream error:(NSString *)error {
    NSLog(@"%@", error);
}


- (void)didStreamRemove:(StringeeRoom *)stringeeRoom stream:(StringeeRoomStream *)stream {
    NSLog(@"Đã xóa stream - streamId: %@", stream.streamId);
    
    // Update UI - hidden containRemoteView1(2,3,4)
    if ([stream.remoteVideoView.superview isEqual:self.containRemoteView1]) {
        self.containRemoteView1.hidden = YES;
    } else if ([stream.remoteVideoView.superview isEqual:self.containRemoteView2]) {
        self.containRemoteView2.hidden = YES;
    } else if ([stream.remoteVideoView.superview isEqual:self.containRemoteView3]) {
        self.containRemoteView3.hidden = YES;
    }else if ([stream.remoteVideoView.superview isEqual:self.containRemoteView4]) {
        self.containRemoteView4.hidden = YES;
    }
    
    if (stream.remoteVideoView.superview) {
        [stream.remoteVideoView removeFromSuperview];
    }
}


// MARK: - Stringee RemoteView Delegate

- (void)videoView:(StringeeRemoteVideoView *)videoView didChangeVideoSize:(CGSize)size {
    
    NSLog(@"VideoView của remote stream đã thay đổi kích thước tới %f - %f", size.width, size.height);
    
    // Get width and height of superview
    CGFloat superWidth = self.containRemoteView1.bounds.size.width;
    CGFloat superHeight = self.containRemoteView1.bounds.size.height;
    
    CGFloat newWidth;
    CGFloat newHeight;
    
    float superScale = superWidth / superHeight;
    float sizeScale = size.width / size.height;
    
    if (superScale < sizeScale) {
        // fix width
        newWidth = superWidth;
        newHeight = superWidth / sizeScale;
        [videoView setFrame:CGRectMake(0, (superHeight - newHeight) / 2, newWidth, newHeight)];
    } else {
        // fix chiều cao
        newHeight = superHeight;
        newWidth = superHeight * sizeScale;
        [videoView setFrame:CGRectMake((superWidth - newWidth) / 2, 0, newWidth, newHeight)];
    }
    
}

// MARK: - Call Quality

- (void)beginCheck {
    hasCheckedStats = YES;
    statsTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(reportStarts) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:statsTimer forMode:NSDefaultRunLoopMode];
}

- (void)reportStarts {
    
    if (arrayRemoteStreams.count) {
        StringeeRoomStream * remoteStream = [arrayRemoteStreams objectAtIndex:0];
        [self.stringeeRoom statsReportForStream:remoteStream useVideoTrack:NO withCompletionHandler:^(NSDictionary<NSString *,NSString *> *stats) {
            [self checkAudioQualityWithStats:stats];
        }];
    }
    
}

- (void)endCheck {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [statsTimer invalidate];
    statsTimer = nil;
}

- (void)checkAudioQualityWithStats:(NSDictionary *) stats {
    long long audioTimeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber *byteReceived = [stats objectForKey:@"bytesReceived"];
    
    if (byteReceived.longLongValue != 0) {
        if (prevAudioTimeStamp == 0) {
            prevAudioTimeStamp = audioTimeStamp;
            
            prevAudioBytes = byteReceived.longLongValue;
        }
        
        if (audioTimeStamp - prevAudioTimeStamp > TIME_WINDOW) {
            
            // Tính tỉ lệ mất gói
            NSNumber *packetLost = stats[@"packetsLost"];
            NSNumber *packetsReceived = stats[@"packetsReceived"];
            
            if (prevAudioPacketReceived != 0) {
                long long pl = packetLost.longLongValue - prevAudioPacketLost;
                long long pr = packetsReceived.longLongValue - prevAudioPacketReceived;
                
                long long pt = pl + pr;
                
                if (pt > 0) {
                    audioPLRatio = (double)pl / (double)pt;
                }
            }
            
            prevAudioPacketLost = packetLost.longLongValue;
            prevAudioPacketReceived = packetsReceived.longLongValue;
            
            // Tính băng thông video
            audioBw = (long long) ((8 * (byteReceived.longLongValue - prevAudioBytes)) / (audioTimeStamp - prevAudioTimeStamp));
            prevAudioTimeStamp = audioTimeStamp;
            prevAudioBytes = byteReceived.longLongValue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (audioBw >= 35000) {
                    
                    [self.imageQuality setImage:[UIImage imageNamed:@"exellent"]];
                    
                } else if (audioBw >= 25000 && audioBw < 35000) {
                    
                    [self.imageQuality setImage:[UIImage imageNamed:@"good"]];
                    
                } else if (audioBw > 15000 && audioBw < 25000) {
                    
                    [self.imageQuality setImage:[UIImage imageNamed:@"average"]];
                    
                } else {
                    [self.imageQuality setImage:[UIImage imageNamed:@"poor"]];
                }
            });
            
        }
    }
}

// MARK: - Action

- (IBAction)switchCameraTapped:(UIButton *)sender {
    if (localStream) {
        [localStream switchCamera];
    }
}

- (IBAction)muteTapped:(UIButton *)sender {
    
    if (localStream) {
        if (isMute) {
            [localStream mute:NO];
            [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"call_unmute"] forState:UIControlStateNormal];
            isMute = NO;
        } else {
            [localStream mute:YES];
            [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"call_mute"] forState:UIControlStateNormal];
            isMute = YES;
        }
    }
    
}

- (IBAction)speakerTapped:(UIButton *)sender {
    
    if (isSpeaker) {
        isSpeaker = NO;
        [[StringeeAudioManager instance] setLoudspeaker:NO];
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"ic_speaker_off"] forState:UIControlStateNormal];
    } else {
        isSpeaker = YES;
        [[StringeeAudioManager instance] setLoudspeaker:YES];
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"ic_speaker_on"] forState:UIControlStateNormal];
    }
        
}

- (IBAction)cameraTapped:(UIButton *)sender {
    // Đang tắt hình thì bật hình truyền vào YES và ngược lại
    if (localStream) {
        if (cameraIsOff) {
            cameraIsOff = NO;
            [localStream turnOnCamera:YES];
            [self.buttonCamera setBackgroundImage:[UIImage imageNamed:@"video_enable"] forState:UIControlStateNormal];
        } else {
            cameraIsOff = YES;
            [localStream turnOnCamera:NO];
            [self.buttonCamera setBackgroundImage:[UIImage imageNamed:@"video_disable"] forState:UIControlStateNormal];
            
        }
    }
    
    
}

- (IBAction)endCallTapped:(UIButton *)sender {
    [self clearAndEnd];
}

- (void)clearAndEnd {
    
    // Remove render view
    if (localStream.localVideoView.superview) {
        [localStream.localVideoView removeFromSuperview];
    }
    
    for (StringeeRoomStream * stream in arrayRemoteStreams) {
        if (stream.remoteVideoView.superview) {
            [stream.remoteVideoView removeFromSuperview];
        }
    }
    
    // Terminate room and release objects
    [self.stringeeRoom destroy];
    
    // Configure Audio Session
    StringeeAudioManager * audioManager = [StringeeAudioManager instance];
    [audioManager audioSessionSetActive:NO error:nil];
    
    // Stop stats report
    [self endCheck];
    
    // Dismiss
    [self dismissViewControllerAnimated:YES completion:^{
        [InstanceManager instance].callingViewController = nil;
    }];
}

@end
