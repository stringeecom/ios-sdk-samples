//
//  CallkitCall.swift
//  stringeex
//
//  Created by HoangDuoc on 12/31/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation
import CallKit

class CallKitCall {
    var serial = 0
    var callId: String?
    var stringeeCall: StringeeCall?
    var uuid: UUID?
    
    var answered = false
    var rejected = false
    
    var audioIsActived = false
    var isIncoming = false
    var answerAction: CXAnswerCallAction?
    
    var timer: Timer?
    var counter = 0
    
    init(isIncoming: Bool, enableTimer: Bool = false) {
        self.isIncoming = isIncoming
        if enableTimer {
            startTimer()
        }
    }
    
    private func startTimer() {
        if timer != nil { return }
        
        stopTimer()
        timer = Timer(timeInterval: 2, target: self, selector: #selector(CallKitCall.handleCallTimeOut), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .default)
        timer?.fire()
    }
    
    @objc private func handleCallTimeOut() {
        counter += 2
        
        if counter >= 28 {
            stopTimer()
            if !answered && !rejected {
                CallManager.shared.endCall()
            }
        }
    }
    
    private func stopTimer() {
        CFRunLoopStop(CFRunLoopGetCurrent())
        timer?.invalidate()
        timer = nil
    }
    
    func clean() {
        stopTimer()
    }
    
    deinit {
        stopTimer()
    }
}
