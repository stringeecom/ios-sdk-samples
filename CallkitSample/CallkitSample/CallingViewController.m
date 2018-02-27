//
//  CallingViewController.m
//  CallkitSample
//
//  Created by Hoang Duoc on 2/10/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "CallingViewController.h"
#import "InstanceManager.h"

@interface CallingViewController ()

@end

@implementation CallingViewController {
    NSTimer *timer;
    int timeSec;
    int timeMin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [InstanceManager instance].callingViewController = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [InstanceManager instance].callingViewController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lbUserId.text = self.strUserId;
    
    if (self.isOutgoingCall) {
        self.seCall = [[StringeeCall alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient from:[StringeeImplement instance].stringeeClient.userId to:self.strUserId];
        self.seCall.callStateDelegate = self;
        [self.seCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            if (!status) {
                // Failed
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    } 

}

- (IBAction)hangupTapped:(UIButton *)sender {
    [self.seCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)didChangeState:(StringeeCall *)stringeeCall stringeeCallState:(StringeeCallState)state reason:(NSString *)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
                
            case STRINGEE_CALLSTATE_INIT: {
                self.labelConnecting.text = @"Init";
            } break;
                
            case STRINGEE_CALLSTATE_CALLING: {
                self.labelConnecting.text = @"Calling";
            } break;
                
            case STRINGEE_CALLSTATE_RINGING: {
                self.labelConnecting.text = @"Ringing";
            } break;
                
            case STRINGEE_CALLSTATE_STARTING: {
                self.labelConnecting.text = @"Starting";
            } break;
                
            case STRINGEE_CALLSTATE_CONNECTED: {
                [self startTimer];
            } break;
                
            case STRINGEE_CALLSTATE_BUSY: {
                [self stopTimer];
                [self dismissViewControllerAnimated:YES completion:nil];
            } break;
                
            case STRINGEE_CALLSTATE_END: {
                [self stopTimer];
                [self dismissViewControllerAnimated:YES completion:nil];
            } break;
                
            default:
                break;
        }
    });
}

- (void)startTimer {
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

//Event called every time the NSTimer ticks.
- (void)timerTick:(NSTimer *)timer {
    timeSec++;
    if (timeSec == 60)
    {
        timeSec = 0;
        timeMin++;
    }
    //Format the string 00:00
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    //Display on your label
    //[timeLabel setStringValue:timeNow];
    self.labelConnecting.text= timeNow;
}

//Call this to stop the timer event(could use as a 'Pause' or 'Reset')
- (void)stopTimer {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timer invalidate];
    timeSec = 0;
    timeMin = 0;
    //Since we reset here, and timerTick won't update your label again, we need to refresh it again.
    //Format the string in 00:00
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    //Display on your label
    // [timeLabel setStringValue:timeNow];
    self.labelConnecting.text= timeNow;
}

@end
