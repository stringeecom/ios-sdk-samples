//
//  Reporter.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/14/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import Foundation

enum InternetQualityType: String {
    case noConnect
    case poor
    case average
    case good
    case exellent
    
    var icon: UIImage {
        switch self {
        case .noConnect: return UIImage(named: "no_connect")!
        case .poor: return UIImage(named: "poor")!
        case .average: return UIImage(named: "average")!
        case .good: return UIImage(named: "good")!
        case .exellent: return UIImage(named: "exellent")!
        }
    }
}

class Reporter {
    static let shared = Reporter()
    private init() { }
    
    let timeWindow = 2;
    
    var audioBw: Double = 0
    var audioPLRatio: Double = 0
    var prevAudioPacketLost: Int64 = 0
    var prevAudioPacketReceived: Int64 = 0
    var prevAudioTimeStamp: Int64 = 0
    var prevAudioBytes: Int64 = 0
    
    func checkAudioQuality(with stats: Dictionary<String, String>?) -> InternetQualityType? {
        guard let stats = stats else { return nil }
        let audioTimeStamp = Date().timeIntervalSince1970
        let byteReceived = Int64(stats["bytesReceived"] ?? "0") ?? 0
        
        guard byteReceived != 0 else { return nil }
        if prevAudioTimeStamp == 0 {
            prevAudioTimeStamp = Int64(audioTimeStamp)
            prevAudioBytes = byteReceived
        }
        
        guard (Int64(audioTimeStamp) - prevAudioTimeStamp) > timeWindow else { return nil }
        let packetLost = Int64(stats["packetsLost"] ?? "0") ?? 0
        let packetsReceived = Int64(stats["packetsReceived"] ?? "0") ?? 0
        
        if prevAudioPacketReceived != 0 {
            let pl = packetLost - prevAudioPacketLost
            let pr = packetsReceived - prevAudioPacketReceived
            if pl + pr > 0 {
                audioPLRatio = Double(pl) / Double(pl + pr)
            }
        }
        
        prevAudioPacketLost = packetLost
        prevAudioPacketReceived = packetsReceived
        
        // Tính băng thông video
        audioBw = Double(8 * (byteReceived - prevAudioBytes)) / Double(Int64(audioTimeStamp) - prevAudioTimeStamp)
        prevAudioTimeStamp = Int64(audioTimeStamp)
        prevAudioBytes = byteReceived
        
        guard StringeeCallCenter.shared.hasConnectedToStringeeServer else { return .noConnect }
        if audioBw >= 35000 { return .exellent }
        else if audioBw >= 25000 && audioBw < 35000 { return .good }
        else if audioBw > 15000 && audioBw < 25000 { return .average}
        else { return .poor }
    }
}
