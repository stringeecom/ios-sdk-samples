//
//  StringeeConstant.swift
//  OneToOneCallSample-Swift
//
//  Created by HoangDuoc on 6/4/21.
//

import Foundation

enum AudioOutputMode {
    case iphone // loa trong
    case speaker // loa ngoai
    case bluetooth // ket noi cac thiet bi khac
}

struct CallControl {
    var isIncoming = false
    var isAppToPhone = false
    var isVideo = false

    var from = ""
    var to = ""
    var username = ""
    var displayName: String {
        if username.count > 0 {
            return username
        } else {
            return isIncoming ? from : to
        }
    }

    var isMute = false
//    var isSpeaker = false
    var audioOutputMode = AudioOutputMode.iphone
    var localVideoEnabled = true
    var signalingState: SignalingState = .calling
    var mediaState: MediaState = .disconnected
}

enum CallScreenType {
    case outgoing
    case incoming
    case calling
}

class TimeCounter {
    var sec: Int = 0
    var min: Int = 0
    var hour: Int = 0

    func timeNow() -> String {
        sec = sec + 1
        if sec == 60 {
            sec = 0
            min = min + 1
        }

        if min == 60 {
            min = 0
            hour = hour + 1
        }

        return currentTime()
    }

    func currentTime() -> String {
        if hour > 0 {
            return String(format: "%02d:%02d:%02d", hour, min, sec)
        } else {
            return String(format: "%02d:%02d", min, sec)
        }
    }

    func hasStarted() -> Bool {
        if sec != 0 || min != 0 || hour != 0 {
            return true
        }

        return false
    }

    func reset() {
        sec = 0
        min = 0
        hour = 0
    }
}

