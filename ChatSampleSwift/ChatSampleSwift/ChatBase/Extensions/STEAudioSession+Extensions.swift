//
//  AudioSession+Extensions.swift
//  stringeex
//
//  Created by HoangDuoc on 3/29/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

extension AVAudioSession {
    static var isHeadphonesConnected: Bool {
        return sharedInstance().isHeadphonesConnected
    }
    
    var isHeadphonesConnected: Bool {
        return !currentRoute.outputs.filter { $0.isHeadphones }.isEmpty
    }
}

extension AVAudioSessionPortDescription {
    var isHeadphones: Bool {
        return portType == AVAudioSession.Port.headphones
    }
}
