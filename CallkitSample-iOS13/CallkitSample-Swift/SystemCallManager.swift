//
//  CallManager.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/11/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import Foundation
import AVKit
import CallKit

enum CallAction {
    case start(id: UUID, handle: CXHandle)
    case answer(id: UUID)
    case end(id: UUID, showInRecentCalls: Bool)
    case setHeld(id: UUID, hold: Bool)
    case mute(id: UUID, muted: Bool)
    //    case group
    //    case playDTMF
    
    var cxCallAction: CXAction {
        switch self {
        case .start(let id, let handle): return CXStartCallAction(call: id, handle: handle)
        case .answer(let id): return CXAnswerCallAction(call: id)
        case .end(let id, _): return CXEndCallAction(call: id)
        case .setHeld(let id, let hold): return CXSetHeldCallAction(call: id, onHold: hold)
        case .mute(let id, let mute): return CXSetMutedCallAction(call: id, muted: mute)
            //        case .group, .playDTMF: return nil
        }
    }
    
    var id: UUID {
        switch self {
        case .start(let id, _), .answer(let id), .end(let id, _), .setHeld(let id, _), .mute(let id, _): return id
        }
    }
}

class SystemCallManager: NSObject {
    static let shared = SystemCallManager()
    private override init(){
        super.init()
    }
    
    private var isUpdatingMuteButton = false
    
    private var currentCallKitId: UUID?
    private(set) var callKitWaitingResponseHandle: (() -> Void)? // Dùng trong trường hợp show CallKit trước sau đó bấn answer button rồi đợi Stringee call đến
    private var waitingAVAudioSessionHandle: (() -> Void)? // Dùng trong trường hợp show CallKit trước sau đó bấn answer button rồi đợi Stringee call đến
    
    private var callController = CXCallController()
    private lazy var provider: CXProvider? = {
        let configuration = providerConfig(includesCallsInRecents: true)
        let provider = CXProvider(configuration: configuration)
        provider.setDelegate(self, queue: DispatchQueue.main)
        return provider
    }()
    
    var isHasCalKitShowing: Bool { return currentCallKitId != nil }
    
    func reportNewIncomingCall(for uuid: UUID, phoneNumber: String, callerName: String, completion: @escaping (Error?) -> Void) {
        guard currentCallKitId == nil else { reportAFakeCall(); return }
        currentCallKitId = uuid
        let updater = CXCallUpdate()
        updater.remoteHandle = CXHandle(type: .generic, value: phoneNumber)
        updater.localizedCallerName = callerName
        
        provider?.reportNewIncomingCall(with: uuid, update: updater, completion: { [weak self] (error) in
            guard let self = self else { return }
            if error == nil {
                self.configureAudioSession()
            } else {
                self.currentCallKitId = nil
                self.callKitWaitingResponseHandle = nil
            }
            completion(error)
        })
    }
    
    func reportAFakeCall() {
        guard CXCallObserver().calls.count == 0 else { return }
        let callUpdate = CXCallUpdate()
        callUpdate.hasVideo = false
        callUpdate.localizedCallerName = "Expired Call"
        
        let fakeCallId = UUID()
        provider?.reportNewIncomingCall(with: fakeCallId, update: callUpdate, completion: { (error) in
            print(error?.localizedDescription ?? "")
            self.request(action: .end(id: fakeCallId, showInRecentCalls: false))
        })
    }
    
    func updateCallInfo(phone: String, callerName: String = "Stringee", isVideo: Bool = false) {
        guard let id = currentCallKitId else { return }
        DispatchQueue.main.async {
            let callUpdate = CXCallUpdate()
            callUpdate.hasVideo = isVideo
            callUpdate.remoteHandle = CXHandle(type: .generic, value: phone)
            callUpdate.localizedCallerName = callerName
            self.provider?.reportCall(with: id, updated: callUpdate)
        }
    }
    
    func updateUI(with action: UserCallingAcion) {
        guard let userId = currentCallKitId else { return }
        switch action {
        case .answer: request(action: .answer(id: userId))
        case .end: request(action: .end(id: userId, showInRecentCalls: true))
        case .mute:
            isUpdatingMuteButton = true
            request(action: .mute(id: userId, muted: StringeeCallCenter.shared.isMute))
        default: break
        }
    }
    
    func updateUI(for state: SignalingState) {
        guard let userId = currentCallKitId else { return }
        switch state {
        case .ended:
            request(action: .end(id: userId, showInRecentCalls: true))
            currentCallKitId = nil
        default: break
        }
    }
}

extension SystemCallManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        guard action.callUUID == currentCallKitId else { action.fulfill(); return }
        configureAudioSession()
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        StringeeCallCenter.shared.userAction(.answer, isFromCallKit: true)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard action.callUUID == currentCallKitId else { action.fulfill(); return }
        
        callKitWaitingResponseHandle = {
            self.configureAudioSession()
            self.waitingAVAudioSessionHandle = { StringeeCallCenter.shared.userAction(.answer, isFromCallKit: true) }
            action.fulfill()
        }
        
        guard StringeeCallCenter.shared.isStringeeCalling else { return }
        callKitWaitingResponseHandle?()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard action.callUUID == currentCallKitId else { action.fulfill(); return }
        
        callKitWaitingResponseHandle = { [weak self] in
            self?.currentCallKitId = nil
            StringeeCallCenter.shared.userAction(.end, isFromCallKit: true)
            action.fulfill()
            self?.callKitWaitingResponseHandle = nil
        }
        
        guard StringeeCallCenter.shared.isStringeeCalling else { action.fulfill(); return }
        callKitWaitingResponseHandle?()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard action.callUUID == currentCallKitId else { action.fulfill(); return }
        if !isUpdatingMuteButton { // Đây là trường hợp người dùng bấn vào mute ở màn call kit
            StringeeCallCenter.shared.userAction(.mute, isFromCallKit: true)
        } else { // Đây là trường hợp bấm vào mute ở my ViewControll mà nó update sang
            isUpdatingMuteButton = false
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        
    }
    
    /// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
    }
    
    /// Called when the provider's audio session activation state changes.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        waitingAVAudioSessionHandle?()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        waitingAVAudioSessionHandle = nil
    }
}

extension SystemCallManager {
    private func request(action: CallAction, completion: ((Error?)->Void)? = nil) {
        DispatchQueue.main.async {
            switch action {
            case .end(_, let isShowInRecentCalls):
                self.provider?.updateConfiguration(includesCallsInRecents: isShowInRecentCalls)
            default: break
            }
            
            let transaction = CXTransaction(action: action.cxCallAction)
            self.callController.request(transaction, completion: completion ?? { _ in })
        }
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setMode(.voiceChat)
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
        } catch(let error) {
            print(error)
        }
    }
    
    private func providerConfig(includesCallsInRecents: Bool) -> CXProviderConfiguration {
        let configuration = CXProviderConfiguration(localizedName: "Stringee")
        configuration.supportsVideo = true
        configuration.maximumCallsPerCallGroup = 1
        configuration.maximumCallGroups = 1
        configuration.supportedHandleTypes = [.generic]
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = includesCallsInRecents
        }
        return configuration
    }
}

fileprivate extension CXProvider {
    func updateConfiguration(includesCallsInRecents: Bool) {
        if #available(iOS 11.0, *) {
            let newConfig = configuration
            guard newConfig.includesCallsInRecents != includesCallsInRecents else { return }
            newConfig.includesCallsInRecents = includesCallsInRecents
            configuration = newConfig
        }
    }
}
