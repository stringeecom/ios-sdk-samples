//
//  StringeeCallCenter.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import UIKit
import PushKit

enum UserCallingAcion {
    case answer
    case end
    case mute
    case speaker
}

enum UserCallingState {
    case caller(CallerState)
    case receiver(ReceiverState)
    case normal
    
    var isNormal: Bool {
        switch self {
        case .normal: return true
        default: return false
        }
    }
    
    enum CallerState {
        case calling
        case ringing
        case busy
        case answered
        case end
    }
    
    enum ReceiverState {
        case waiting
        case answered
        case end
    }
}

protocol StringeeCallingVCProtocol: class {
    func updateUI(with action: UserCallingAcion)
    func updateUI(for state: SignalingState)
    func didChangeMediaState(mediaState: MediaState)
}

class StringeeCallCenter: NSObject {
    static var shared = StringeeCallCenter()
    private override init() {
        super.init()
        stringeeClient = StringeeClient(connectionDelegate: self)
        stringeeClient?.incomingCallDelegate = self
    }
    
    // user1
//   private let myAccessToken = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzLTE1ODM0ODE1ODQiLCJpc3MiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzIiwiZXhwIjoxNTg2MDczNTg0LCJ1c2VySWQiOiJ1c2VyMSJ9.hdJlsOT6C7gziGjE88gQ9_NX-HQHZjkgWKJlkxavetM"
    
    // user2
   private let myAccessToken =  "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzLTE1ODM0ODE2MzkiLCJpc3MiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzIiwiZXhwIjoxNTg2MDczNjM5LCJ1c2VySWQiOiJ1c2VyMiJ9.ZlEKcixSi09QnyT3Qh6k0_R5jLfChmEqnFE1ksIrm4E"
    
    // user3
//    private let myAccessToken = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzLTE1ODM0ODE2NjkiLCJpc3MiOiJTS2NGeHVtOUhPMkpxNkRVTjRuaEc5dFhQVVVWVGQySzFzIiwiZXhwIjoxNTg2MDczNjY5LCJ1c2VySWQiOiJ1c2VyMyJ9.AxF2U-lzF4j64JWKWugx23s6IxszdvCmRMxCBEpB2Eo"
    
    
    private var stringeeClient: StringeeClient!
    private var currentStringeeCall: StringeeCall?
    private var userCallingState: UserCallingState = .normal
    
    private(set) var isMute = false
    private(set) var isSpeaker = false
    
    var hasConnectedToStringeeServer: Bool { return stringeeClient.hasConnected }
    var isStringeeCalling: Bool { return currentStringeeCall != nil }
    
    func connectToStringeeServer() {
        stringeeClient.connect(withAccessToken: myAccessToken)
    }
    
    func userAction(_ action: UserCallingAcion, isFromCallKit: Bool = false) {
        switch action {
        case .answer:
            currentStringeeCall?.answer(completionHandler: { (status, code, message) in
                print(message ?? "")
            })
        case .end:
            guard let call = currentStringeeCall else { break }
            switch userCallingState {
            case .caller(_): call.hangup(completionHandler: nil)
            case .receiver(let state):
                switch state {
                case .answered: call.hangup(completionHandler: nil)
                case .waiting: call.reject(completionHandler: nil)
                case .end: break
                }
            case .normal: break
            }
            currentStringeeCall = nil
        case .mute:
            guard let call = currentStringeeCall else { break }
            isMute = !isMute
            call.mute(isMute)
        case .speaker:
            isSpeaker = !isSpeaker
            StringeeAudioManager.instance()?.setLoudspeaker(isSpeaker)
        }
        
        updateState(with: action)
        InstanceManager.shared.myCallingVCUpdateUI(with: action, stringeeCall: currentStringeeCall)
        if !isFromCallKit {
            SystemCallManager.shared.updateUI(with: action)
        }
    }
    
    func makeCall(to userId: String, completion: ((_ success: Bool, _ message: String?) -> Void)? = nil) {
        guard stringeeClient.hasConnected else { return }
        currentStringeeCall = StringeeCall(stringeeClient: stringeeClient, from: stringeeClient.userId, to: userId)
        currentStringeeCall?.delegate = self
        currentStringeeCall?.make(completionHandler: { (success, code, message, data) in
            guard success else { self.currentStringeeCall = nil; return }
            self.userCallingState = .caller(.calling)
            completion?(success, message)
        })
            
        InstanceManager.shared.showMyCallingVC(with: currentStringeeCall!)
    }
    
    func registerPush(with pushCredentials: PKPushCredentials) {
        guard !InstanceManager.shared.hasRegisteredToReceivePush else { return }
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        stringeeClient.registerPush(forDeviceToken: token, isProduction: false, isVoip: true) { (success, code, message) in
            print(message ?? "")
            guard success else { return }
            InstanceManager.shared.hasRegisteredToReceivePush = true
        }
    }
    
    func pushKitHandler(with payload: PKPushPayload) {
        guard userCallingState.isNormal else { SystemCallManager.shared.reportAFakeCall(); return }
        
        // Valid du lieu
        guard let jsonDic = (payload.dictionaryPayload[AnyHashable("data")] as? [String: Any])?["map"] as? [String: Any],
            let callData = (jsonDic["data"] as? [String: Any])?["map"] as? [String: String],
            let callStatus = callData["callStatus"],
            let callId = callData["callId"],
            let pushType = jsonDic["type"] as? String else { SystemCallManager.shared.reportAFakeCall(); return }
        
        guard pushType == "CALL_EVENT", callStatus == "started", !callId.isEmpty else { SystemCallManager.shared.reportAFakeCall(); return }
        
        // Show 1 cuộc gọi chưa có đủ thông tin hiển thị => Update khi nhận được incoming call
        SystemCallManager.shared.reportNewIncomingCall(for: UUID(), phoneNumber: "0123456789", callerName: "Connecting Call...") { (error) in
            print("Show a call and update when incoming call")
        }
    }
    
    func updateSpeaker() {
        InstanceManager.shared.checkAndUpdateSpeaker { (isSpeaker) in
            guard isStringeeCalling else { return }
            self.isSpeaker = isSpeaker
        }
    }
}

// Support function
extension StringeeCallCenter {
    private func updateState(with action: UserCallingAcion) {
        switch action {
        case .answer:
            switch userCallingState {
            case .receiver(_): userCallingState = .receiver(.answered)
            case .caller(_): userCallingState = .caller(.answered)
            case .normal: break
            }
        case .end: userCallingState = .normal
        default: break
        }
    }
}

extension StringeeCallCenter: StringeeIncomingCallDelegate {
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {
        guard !isStringeeCalling else { stringeeCall.reject(completionHandler: nil); return }
        currentStringeeCall = stringeeCall
        currentStringeeCall?.delegate = self
        currentStringeeCall?.initAnswer()
        
        // App đang chết và nhận được push => đã show CallKit nên chỉ update thông tin
        if SystemCallManager.shared.isHasCalKitShowing {
            InstanceManager.shared.showMyCallingVC(with: stringeeCall)
            SystemCallManager.shared.updateCallInfo(phone: stringeeCall.from, callerName: stringeeCall.fromAlias)
            DispatchQueue.main.async {
                //Nếu chưa bấm answer thì thôi, còn đã bấm answere rồi thì trả answer luôn
                SystemCallManager.shared.callKitWaitingResponseHandle?()
            }
            
        } else {
            // Đang trong app và nhận được Stringee call trước show CallKit mới
            userCallingState = .receiver(.waiting)
            SystemCallManager.shared.reportNewIncomingCall(for: UUID(), phoneNumber: stringeeCall.from, callerName: stringeeCall.fromAlias) { error in
                if error == nil {
                    InstanceManager.shared.showMyCallingVC(with: stringeeCall)
                } else {
                    stringeeCall.reject { (status, code, message) in
                        print("***** Reject - \(message ?? "")")
                    }
                }
            }
        }
    }
}

extension StringeeCallCenter: StringeeCallDelegate {
    func didChangeSignalingState(_ stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        print("SignalingState: \(signalingState.rawValue)")
        switch userCallingState {
        case .caller(_): userCallingState = .caller(signalingState.toCallerState())
        case .receiver(_): userCallingState = .receiver(signalingState.toReceiverState())
        case .normal: break
        }
        InstanceManager.shared.myCallingVCUpdateUI(for: signalingState)
        SystemCallManager.shared.updateUI(for: signalingState)
        
        if signalingState == .ended || signalingState == .busy {
            currentStringeeCall = nil
        }
    }
    
    func didChangeMediaState(_ stringeeCall: StringeeCall!, mediaState: MediaState) {
        InstanceManager.shared.myCallingVCDidChangeMediaState(mediaState: mediaState)
    }
    
    func didHandle(onAnotherDevice stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        print("didHandle onAnotherDevice: \(signalingState.rawValue)---\(reason ?? "_")---\(sipCode)-\(sipReason ?? "_")")
        guard signalingState == .answered else { return }
        InstanceManager.shared.myCallingVCUpdateUI(for: .ended)
        SystemCallManager.shared.updateUI(for: .ended)
        currentStringeeCall = nil
    }
}

extension StringeeCallCenter: StringeeConnectionDelegate {
    func requestAccessToken(_ stringeeClient: StringeeClient!) {
        stringeeClient.connect(withAccessToken: myAccessToken)
    }
    
    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect")
        (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.viewControllers.first?.title = stringeeClient.userId
    }
    
    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect")
    }
    
    func didFailWithError(_ stringeeClient: StringeeClient!, code: Int32, message: String!) {
        print("didFailWithError - \(message ?? "")")
    }
}

private extension SignalingState {
    func toCallerState() -> UserCallingState.CallerState {
        switch self {
        case .calling: return .calling
        case .ringing: return .ringing
        case .busy: return .busy
        case .answered: return .answered
        case .ended: return .end
        @unknown default:
            fatalError()
        }
    }
    
    func toReceiverState() -> UserCallingState.ReceiverState {
        switch self {
        case .ended: return .end
        default: return .waiting
        }
    }
}
