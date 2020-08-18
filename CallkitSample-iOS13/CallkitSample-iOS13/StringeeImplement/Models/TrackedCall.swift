//
//  TrackedCall.swift
//  stringeex
//
//  Created by HoangDuoc on 1/22/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//  Track thông tin cuộc gọi cho việc route nhiều lần của stringeeX và đồng bộ Pushkit với IncomingCall event
//

import Foundation

class TrackedCall {
    var serial = 0
    var callId: String
    
    var receivedIncomingPush = false {
        willSet(newValue) {
            
        }
    }
    
    var receivedIncomingCall = false {
        willSet(newValue) {
            
        }
    }
    
    var ended = false
    
    init(id: String) {
        self.callId = id
    }
}
