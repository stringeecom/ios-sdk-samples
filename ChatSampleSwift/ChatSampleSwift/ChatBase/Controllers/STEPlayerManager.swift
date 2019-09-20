//
//  STEPlayerManager.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 5/13/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

let STEPlayerManagerIdKey = "id"
let STEPlayerManagerCurrentTimeKey = "CurrentTime"

class STEPlayerManager: NSObject {
    static let shared = STEPlayerManager()
    
    //    var queuePlayer: AVQueuePlayer!
    var currentItemId: String?
//    var currentTime: Int = 0
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    
    override init() {
        super.init()
        //        queuePlayer = AVQueuePlayer()
        //
        //        if #available(iOS 10.0, *) {
        //            queuePlayer.automaticallyWaitsToMinimizeStalling = false
        //        }
        //
        //        queuePlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
        //            if self.queuePlayer.currentItem?.status == .readyToPlay {
        //                let currentTime: Float64 = CMTimeGetSeconds(self.queuePlayer.currentTime())
        //                self.currentTime = Int(currentTime.rounded(.toNearestOrAwayFromZero))
        //
        //                let userInfo = [STEPlayerManagerIdKey: self.currentItemId ?? "",
        //                                "currentTime": self.currentTime
        //                    ] as [String : Any]
        //                NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerTrackingNotification, object: nil, userInfo: userInfo)
        //            } else {
        //                print("============ Lỗi player ko thể chơi nhạc")
        //                let userInfo = [STEPlayerManagerIdKey: self.currentItemId ?? ""] as [String : Any]
        //                NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil, userInfo: userInfo)
        //                self.currentItemId = nil
        //            }
        //        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(STEPlayerManager.handleAudioSessionInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }
    
    func play(filePath: URL) -> Bool {
        if filePath.path == currentItemId {
            // item đang được player rồi
            //            if queuePlayer.rate != 0 && queuePlayer.error == nil {
            //                // Playing
            //                queuePlayer.pause()
            //                return false
            //            } else {
            //                queuePlayer.play()
            //                return true
            //            }
            
            guard let aPlayer = self.audioPlayer else {
                return false
            }
            
            if aPlayer.isPlaying {
                aPlayer.pause()
                return false
            } else {
                aPlayer.play()
                return true
            }
        }
        
        // Dừng item cũ nếu đang play
        if self.currentItemId?.count ?? 0 > 0 {
            let userInfo = [STEPlayerManagerIdKey: self.currentItemId ?? ""] as [String : Any]
            NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil, userInfo: userInfo)
        }
        
        // Cấu hình audiosession ra loa ngoài
        if !AVAudioSession.isHeadphonesConnected {
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            } else {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: filePath)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentItemId = filePath.path
            
            // Chạy timer tracking
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(STEPlayerManager.handleTimerTracking), userInfo: nil, repeats: true)
            timer?.fire()
            
            return true
        } catch {
            // Fail
            print("Play audio error: \(error.localizedDescription)")
            audioPlayer = nil
            currentItemId = nil
//            currentTime = 0
            return false
        }
        
        //        // Dừng item cũ nếu đang play
        //        if self.currentItemId?.count ?? 0 > 0 {
        //            let userInfo = [STEPlayerManagerIdKey: self.currentItemId ?? ""] as [String : Any]
        //            NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil, userInfo: userInfo)
        //        }
        //
        //        // Play item mới
        //        currentItemId = filePath.path
        //
        //        let playerItem = AVPlayerItem(url: filePath)
        //        NotificationCenter.default.addObserver(self, selector: #selector(STEPlayerManager.handlePlayerItemDidFinishPlaying(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        //
        //        if !AVAudioSession.isHeadphonesConnected {
        //            if #available(iOS 10.0, *) {
        //                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        //            } else {
        ////                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
        //            }
        //        }
        //
        //        queuePlayer.replaceCurrentItem(with: playerItem)
        //        queuePlayer.volume = 1
        //        queuePlayer.play()
    }
    
    func pause() {
        //        queuePlayer.pause()
    }
    
    func seekTo(time: Float, duration: Double, completion: @escaping (Bool) -> Void) {
        let seconds : Double = Double(Float64(time) * Float64(duration))
        //        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        audioPlayer?.stop()
        audioPlayer?.currentTime = seconds
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        completion(true)
        
        //        queuePlayer.pause()
        //
        //        queuePlayer.seek(to: targetTime) { (status) in
        //            self.queuePlayer.play()
        //            completion(status)
        //        }
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
        //        if (queuePlayer.rate != 0 && queuePlayer.error == nil) {
        //            return true
        //        } else {
        //            return false
        //        }
    }
    
    func stopAndClear() {
        // Bắn end noti
        let userInfo = [STEPlayerManagerIdKey: currentItemId ?? ""] as [String : Any]
        NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil, userInfo: userInfo)
        
        //        queuePlayer.pause()
        //        queuePlayer.replaceCurrentItem(with: nil)
        //        queuePlayer.removeAllItems()
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        timer?.invalidate()
        timer = nil
        
        currentItemId = ""
//        currentTime = 0
    }
    
    func currentTime() -> Int {
        return Int((audioPlayer?.currentTime ?? 0).rounded(.toNearestOrAwayFromZero))
    }
    
    @objc private func handleTimerTracking() {
        let userInfo = [STEPlayerManagerIdKey: self.currentItemId ?? "",
                        "currentTime": currentTime()
            ] as [String : Any]
        NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerTrackingNotification, object: nil, userInfo: userInfo)
    }
    
    //    @objc private func handlePlayerItemDidFinishPlaying(notification: Notification) {
    //        if let item = notification.object as? AVPlayerItem, let identifier = currentItemId, identifier.count > 0 {
    //            NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: item)
    //
    //            let userInfo = [STEPlayerManagerIdKey: currentItemId ?? ""] as [String : Any]
    //            NotificationCenter.default.post(name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil, userInfo: userInfo)
    //
    //            if identifier == self.currentItemId {
    //                self.currentItemId = nil
    //            }
    //        }
    //    }
}

extension STEPlayerManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAndClear()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopAndClear()
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        stopAndClear()
    }
}
