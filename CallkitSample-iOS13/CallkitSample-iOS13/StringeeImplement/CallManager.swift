//
//  SXCallkitManager.swift
//  stringeex
//
//  Created by HoangDuoc on 12/26/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation
import CallKit
import CoreTelephony
import PushKit
import SwiftyJSON

class CallManager: NSObject {
    
    // MARK: - Init
    
    static let shared = CallManager()
    
    var call: CallKitCall? // cac thao tac den call se duoc goi trong main thread
    lazy var trackedCalls = [String: CallKitCall]()
    var audioIsActived = false
    
    private var _provider: AnyObject?
    private var provider: CXProvider {
        if _provider == nil {
            let configuration = CXProviderConfiguration(localizedName: "Stringee")
            configuration.supportsVideo = true
            configuration.maximumCallGroups = 1
            configuration.maximumCallsPerCallGroup = 1
            configuration.supportedHandleTypes = [.generic, .phoneNumber]
            _provider = CXProvider(configuration: configuration)
        }
        
        return _provider as! CXProvider
    }
    
    private var _callController: AnyObject?
    private var callController: CXCallController {
        if _callController == nil {
            _callController = CXCallController()
        }
        
        return _callController as! CXCallController
    }
    
    private var _callObserver: AnyObject?
    private var callObserver: CXCallObserver {
        if _callObserver == nil {
            _callObserver = CXCallObserver()
        }
        
        return _callObserver as! CXCallObserver
    }
    
    var watingForUpdateCallKit: (() -> Void)?
    var showingCallKitUUID: UUID?
    var delayTime: Double = 0
    
    override init() {
        super.init()
        provider.setDelegate(self, queue: DispatchQueue.main)
    }
    
    // MARK: - Actions
    
    func hasSystemCall() -> Bool {
        return callObserver.calls.count > 0
        
        // Tham khao
//        for call in CXCallObserver().calls {
//            if call.hasEnded == false {
//                return true
//            }
//        }
//        return false
    }
    
    func reportIncomingCall(phone: String, callerName: String, isVideo: Bool, completion: @escaping (Bool, UUID) -> ()) {
        let callUpdate = CXCallUpdate()
        callUpdate.hasVideo = isVideo
        callUpdate.remoteHandle = CXHandle(type: .generic, value: phone)
        callUpdate.localizedCallerName = callerName
        let uuid = UUID()
        print("REPORT AN INCOMING CALL \(uuid.uuidString)")
        
        showingCallKitUUID = uuid
        provider.reportNewIncomingCall(with: uuid, update: callUpdate) {[weak self] (error) in
            guard let self = self else { completion(false, uuid); return }
            
            self.watingForUpdateCallKit?()
            self.watingForUpdateCallKit = nil
            self.showingCallKitUUID = nil
            
            if error == nil {
                self.configureAudioSession()
                completion(true, uuid)
            } else {
                completion(false, uuid)
            }
        }
        
    }
    
    func reportUpdatedCall(phone: String, callerName: String, isVideo: Bool, uuid: UUID) {
        let callUpdate = CXCallUpdate()
        callUpdate.hasVideo = isVideo
        callUpdate.remoteHandle = CXHandle(type: .generic, value: phone)
        callUpdate.localizedCallerName = callerName
        provider.reportCall(with: uuid, updated: callUpdate)
    }
    
    func startCall(phone: String, calleeName: String, isVideo: Bool, stringeCall: StringeeCall) {
        if (call != nil) {
            return
        }
        
        let handle = CXHandle(type: .generic, value: phone)
        call = CallKitCall(isIncoming: false)
        call?.uuid = UUID()
        call?.stringeeCall = stringeCall
        call?.callId = stringeCall.callId
        
        let startCallAction = CXStartCallAction(call: (call?.uuid)!, handle: handle)
        startCallAction.isVideo = isVideo
        startCallAction.contactIdentifier = calleeName
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        requestTransaction(transaction: transaction)
    }
    
    func endCall() {
        if let uuid = self.call?.uuid {
            provider.updateConfiguration(includesCallsInRecents: true)
            let endCallAction = CXEndCallAction(call: uuid)
            let transaction = CXTransaction()
            transaction.addAction(endCallAction)
            requestTransaction(transaction: transaction)
        }
    }
    
    func answerCallkitCall() {
        if let uuid = self.call?.uuid {
            provider.updateConfiguration(includesCallsInRecents: true)
            let endCallAction = CXAnswerCallAction(call: uuid)
            let transaction = CXTransaction()
            transaction.addAction(endCallAction)
            requestTransaction(transaction: transaction)
        }
    }
    
    func holdCall(hold: Bool) {
        if let uuid = self.call?.uuid {
            let holdCallAction = CXSetHeldCallAction(call: uuid, onHold: hold)
            let transaction = CXTransaction()
            transaction.addAction(holdCallAction)
            requestTransaction(transaction: transaction)
        }
    }
    
    func requestTransaction(transaction: CXTransaction) {
        callController.request(transaction) { [unowned self] (error) in
            if error != nil {
                print("requestTransaction: \(String(describing: error?.localizedDescription))")
                // End Callkit va xoa current call
                self.endCall()
                self.call?.clean()
                self.call = nil
                
                // Co man hinh calling => dismiss
                if let callingVC = InstanceManager.shared.callingVC {
                    callingVC.endCallAndDismis()
                }
            }
        }
    }
    
    func configureAudioSession() {
        print("CONFIGURE AUDIO SESSION")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
        } catch  {
            print("Cấu hình audio session cho callkit thất bại")
        }
    }
}

// MARK: - Handle iOS 13

extension CallManager {
    
    func handleIncomingPushEvent(payload: PKPushPayload, completion: @escaping () -> Void) {
        let jsonData = JSON(payload.dictionaryPayload)
        print("handleIncomingPushEvent: \(jsonData)")
        let payLoadData = jsonData["data"]["map"]["data"]["map"]
        guard let callStatus = payLoadData["callStatus"].string,
            let callId = payLoadData["callId"].string,
            let pushType = jsonData["data"]["map"]["type"].string,
            !callStatus.isEmpty, !callId.isEmpty, callStatus == "started", pushType == "CALL_EVENT" else {
                // Report 1 cuộc gọi fake và reject luôn => cho các trường hợp không thoả mãn
                CallManager.shared.reportAFakeCall(completion: completion)
                return
        }
        
        if call != nil {
            CallManager.shared.reportAFakeCall(completion: completion)
            return
        }
        
        // Đã show rồi thì thôi
        let callSerial = jsonData["data"]["map"]["data"]["map"]["serial"].intValue
        if let _ = getTrackedCall(callId: callId, serial: callSerial) {
            CallManager.shared.reportAFakeCall(completion: completion)
            return
        }
                
        // Show 1 cuộc gọi chưa có đủ thông tin hiển thị => Update khi nhận được incoming call
        call = CallKitCall(isIncoming: true, enableTimer: true)
        call?.callId = callId
        call?.serial = callSerial
        trackCall(call!)
        
        
        let alias = payLoadData["from"]["map"]["alias"].string
        let number = payLoadData["from"]["map"]["number"].string
        var phone: String
        if let from = call?.stringeeCall?.from, !from.isEmpty {
            phone = from
        } else {
            phone = number ?? ""
        }
        
        var callerName: String
        if let fromAlias = call?.stringeeCall?.fromAlias, !fromAlias.isEmpty {
            callerName = fromAlias
        } else {
            callerName = alias ?? number ?? "Connecting Call..."
        }
        
        reportIncomingCall(phone: phone, callerName: callerName, isVideo: false) { [unowned self] (status, uuid) in
            DispatchQueue.main.async {
                if (status) {
                    // thành công thì gán lại uuid
                    self.call?.uuid = uuid
                    if let stringeeCall = self.call?.stringeeCall {
                        self.updateCallkitInfoFor(stringeeCall: stringeeCall, uuid: uuid)
                    }
                    
                } else {
                    // thất bại thì xoá call
                    self.call?.clean()
                    self.call = nil
                }
                
                completion()
            }
        }
        
        // có push nhưng không có incomingCall
        startCheckingReceivingTimeoutOfStringeeCall()
    }
    
    func updateCallkitInfoFor(stringeeCall: StringeeCall, uuid: UUID) {
        reportUpdatedCall(phone: stringeeCall.from, callerName: stringeeCall.fromAlias, isVideo: stringeeCall.isVideoCall, uuid: uuid)
    }
    
    func handleIncomingCallEvent(stringeeCall: StringeeCall) {
        
        func showCallKitFor(stringeeCall: StringeeCall) {
            call = CallKitCall(isIncoming: true, enableTimer: true)
            call?.callId = stringeeCall.callId
            call?.stringeeCall = stringeeCall
            call?.serial = Int(stringeeCall.serial)
            trackCall(call!)
            
            reportIncomingCall(phone: stringeeCall.from, callerName: stringeeCall.fromAlias, isVideo: stringeeCall.isVideoCall) { [unowned self] (status, uuid) in
                if (status) {
                    // thành công thì gán lại uuid
                    self.call?.uuid = uuid
                    InstanceManager.shared.callingVC?.btAnswer.isEnabled = true
                    InstanceManager.shared.callingVC?.btReject.isEnabled = true
                    
                    if let stringeeCall = self.call?.stringeeCall {
                        self.updateCallkitInfoFor(stringeeCall: stringeeCall, uuid: uuid)
                    }
                } else {
                    self.call?.clean()
                    self.call = nil
                }
            }
        }
        
        func showCallingVC(stringeeCall: StringeeCall) {
            if InstanceManager.shared.callingVC != nil {
                stringeeCall.reject { (status, code, message) in
                    print(message ?? "")
                }
                return
            }
            
            DispatchQueue.main.async {
                let callControl = CallControl()
                let callingVC = CallingViewController.init(control: callControl, call: stringeeCall)
                stringeeCall.delegate = callingVC
                callingVC.modalPresentationStyle = .fullScreen
                
                UIApplication.shared.keyWindow?.rootViewController?.present(callingVC, animated: true, completion: nil)
            }
        }
        
        DispatchQueue.main.async {
            if self.call == nil && InstanceManager.shared.callingVC == nil {
                // Chưa show callkit thì show
                showCallKitFor(stringeeCall: stringeeCall)
                showCallingVC(stringeeCall: stringeeCall)
                stringeeCall.initAnswer()
                self.answerCallWithCondition(shouldChangeUI: false)
                return
            }
            
            if let callId = self.call?.callId, callId == stringeeCall.callId, InstanceManager.shared.callingVC == nil {
                if let uuid = self.call?.uuid {
                    // Nếu đã show callkit cho call này rồi => update thông tin
                    self.updateCallkitInfoFor(stringeeCall: stringeeCall, uuid: uuid)
                } else {
                    self.watingForUpdateCallKit = { [weak self] in
                        if let uuid = self?.showingCallKitUUID, let stCall = self?.call?.stringeeCall {
                            self?.updateCallkitInfoFor(stringeeCall: stCall, uuid: uuid)
                        }
                    }
                }
                self.call?.stringeeCall = stringeeCall
                showCallingVC(stringeeCall: stringeeCall)
                stringeeCall.initAnswer()
                self.answerCallWithCondition(shouldChangeUI: false)
            } else {
                // Đang show cho call khác thì reject call mới. Vẫn có thể có push đến sau nên cần track để không show nữa
                let rejectedCall = CallKitCall(isIncoming: true)
                rejectedCall.callId = stringeeCall.callId
                rejectedCall.serial = Int(stringeeCall.serial)
                self.trackCall(rejectedCall)
                
                stringeeCall.reject { (status, code, message) in
                    print("REJECT INCOMING CALL BECAUSE CALLKIT IS SHOWN")
                }
            }
        }
    }
    
    func reportAFakeCall(completion: @escaping () -> Void) {
        let callUpdate = CXCallUpdate()
        callUpdate.hasVideo = false
        //        callUpdate.remoteHandle = CXHandle(type: .generic, value: "0123456789")
        callUpdate.localizedCallerName = "Expired Call"
        let uuid = UUID()
        
        print("SHOW A FAKE CALLKIT \(uuid.uuidString)")
        provider.reportNewIncomingCall(with: uuid, update: callUpdate) {[unowned self] (error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.provider.updateConfiguration(includesCallsInRecents: false)
                let endCallAction = CXEndCallAction(call: uuid)
                let transaction = CXTransaction(action: endCallAction)
                self.callController.request(transaction) { error in
                    if error != nil {
                        print("FAKE CALL === END CALLKIT ERROR \(error!.localizedDescription)")
                    }
                }
                
                completion()
            }
        }
        
    }
    
    // Sau 4s từ khi connected hoặc nhận push mà không nhận được incomingCall event - Trường hợp nhận được push, nhưng call bị ngắt ngay nên ko nhận được incomingCall
    func startCheckingReceivingTimeoutOfStringeeCall() {
        print("startCheckingReceivingTimeoutOfStringeeCall")
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CallManager.checkReceivingTimeout), object: nil)
        perform(#selector(CallManager.checkReceivingTimeout), with: nil, afterDelay: 15)
    }
    
    func stopCheckingReceivingTimeoutOfStringeeCall() {
        print("stopCheckingReceivingTimeoutOfStringeeCall")
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(CallManager.checkReceivingTimeout), object: nil)
        }
    }
    /*
     Fix lỗi timeout giữa push và call ngắn dẫn đến lỗi khi mạng yếu thì cuộc gọi đến bị ngắt nhanh do chưa kết nối thành công tới Stringee Server.
     Cách fix:
     1. Tăng timeout giữa thời điểm nhận push và nhận incomingCall lên 15s
     2. Sau khi kết nối tới StringeeServer thì check nếu không có call thì ngắt callkit
     **/
    func checkExistIncomingCallIfNeed() {
        print("checkExistIncomingCallIfNeed")
        DispatchQueue.main.async { [unowned self] in
            guard let call = self.call else {
                return
            }
                        
            // Đã show callkit nhưng chưa có stringeeCall thì mới check
            if let callId = call.callId, !callId.isEmpty, call.uuid != nil && call.stringeeCall == nil {
                StringeeImplement.shared.stringeeClient.existIncomingCall(withCallId: callId, completion: { [unowned self] status, code, message, exist in
                    // Neu call khong ton tai thi can end callkit
                    if status && !exist {
                        self.stopCheckingReceivingTimeoutOfStringeeCall()
                        self.checkReceivingTimeout(callId: callId)
                    }
                })
            }
        }
    }
    
    @objc private func checkReceivingTimeout(callId: String? = nil) {
        DispatchQueue.main.async {
            print("checkReceivingTimeout")
            guard let call = self.call else {
                return
            }
            
            if let callId = callId, let currentCallId = call.callId, callId != currentCallId {
                return
            }
            
            // Đã show callkit nhưng chưa có stringeeCall => End callkit
            if call.uuid != nil && call.stringeeCall == nil {
                self.endCall()
                // Tắt màn hình cuộc gọi luôn, fix bug trường hợp gọi hangup nhưng ko có callback từ server
                if let callingVC = InstanceManager.shared.callingVC {
                    callingVC.endCallAndDismis()
                }
            }
        }
    }
    
    
}

// MARK: - Call Actions

extension CallManager {
    
    func answer(shouldChangeUI: Bool = true) {
        if let callingVC = InstanceManager.shared.callingVC, shouldChangeUI {
            callingVC.callControl.signalingState = .answered
            callingVC.updateScreen()
        }
                
        guard let stringeeCall = call?.stringeeCall else { return }
        
        if let answerAction = self.call?.answerAction {
            answerAction.fulfill()
            self.call?.answerAction = nil
            return
        }
        
        stringeeCall.answer { [unowned self] (status, code, message) in
            if let callingVC = InstanceManager.shared.callingVC, !status {
                callingVC.endCallAndDismis()
                return
            }

            if !status {
                self.endCall()
            }
        }
    }
    
    func reject(_ stringeeCall: StringeeCall? = nil) {
        call?.rejected = true
        
        var callNeedToReject: StringeeCall? = nil
        if let seCall = stringeeCall {
            callNeedToReject = seCall
        } else if let seCall = call?.stringeeCall {
            callNeedToReject = seCall
        } else {
            return
        }
        
        callNeedToReject?.reject { [unowned self] (status, code, message) in
            if let callingVC = InstanceManager.shared.callingVC {
                callingVC.endCallAndDismis()
            }
            
//            if !status {
                self.endCall() // cứ reject thì phải end callkit => thử để fix lỗi 486
//            }
        }
    }
    
    func hangup(_ stringeeCall: StringeeCall? = nil) {
        var callNeedToHangup: StringeeCall? = nil
        if let seCall = stringeeCall {
            callNeedToHangup = seCall
        } else if let seCall = call?.stringeeCall {
            callNeedToHangup = seCall
        } else {
            // Không có cuộc gọi thì cần tắt màn hình cuộc gọi
            if let callingVC = InstanceManager.shared.callingVC {
                callingVC.endCallAndDismis()
            }
            return
        }
        
        //        guard let stringeeCall = call?.stringeeCall else { return }
        
        callNeedToHangup?.hangup { [unowned self] (status, code, message) in
            print("====== HANGUP \(String(describing: message))")
            if let callingVC = InstanceManager.shared.callingVC {
                callingVC.endCallAndDismis()
            }
            
//            if !status {
                self.endCall() // cứ hangup thì phải end callkit => thử để fix lỗi 486
//            }
        }
    }
    
    func mute(completion: ((Bool) -> Void)? = nil) {
        guard let callingVC = InstanceManager.shared.callingVC, let stringeeCall = call?.stringeeCall else {
            completion?(false)
            return
        }
        stringeeCall.mute(!callingVC.callControl.isMute)
        callingVC.callControl.isMute = !callingVC.callControl.isMute
        completion?(true)
    }
    
    private func answerCallWithCondition(shouldChangeUI: Bool = true) {
        guard let callkitCall = call else { return }
        
        if callkitCall.isIncoming && callkitCall.answered && (callkitCall.audioIsActived || callkitCall.answerAction != nil) {
            answer(shouldChangeUI: shouldChangeUI)
        }
    }
}

// MARK: - Mapping Call

extension CallManager {
    private func trackCall(_ callNeedToTrack: CallKitCall) {
        let key = callNeedToTrack.callId! + "-" + callNeedToTrack.serial.description
        trackedCalls[key] = callNeedToTrack
    }
    
    private func getTrackedCall(callId: String, serial: Int) -> CallKitCall? {
        let key = callId + "-" + serial.description
        return trackedCalls[key]
    }
}

// MARK: - Callkit Delegate

@available(iOS 10.0, *)
extension CallManager: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("CXStartCallAction")
        configureAudioSession()
        
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        provider.reportOutgoingCall(with: action.callUUID, connectedAt: nil)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("======== CALLKIT ANSWERED \(action.callUUID)")
        if call?.uuid?.uuidString != action.callUUID.uuidString {
            action.fulfill()
            return
        }
        
        call?.answered = true
        call?.answerAction = action
        call?.clean()
        answerCallWithCondition()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("======== CALLKIT ENDED \(action.callUUID)")
        if let uuidString = call?.uuid?.uuidString, uuidString != action.callUUID.uuidString {
            action.fulfill()
            return
        }
        
        call?.clean()
        
        guard let callkitCall = call, let stringeeCall = callkitCall.stringeeCall else {
            action.fulfill()
            call = nil
            // Không có cuộc gọi thì cần tắt màn hình cuộc gọi
            if let callingVC = InstanceManager.shared.callingVC {
                callingVC.endCallAndDismis()
            }
            return
        }
        
        call = nil
        
        if stringeeCall.signalingState != .busy && stringeeCall.signalingState != .ended {
            if callkitCall.isIncoming && !callkitCall.answered {
                reject(stringeeCall)
            } else {
                hangup(stringeeCall)
            }
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("CXSetHeldCallAction")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("CXSetMutedCallAction")
        mute { (status) in
            if status {
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("didActivate audioSession")
        call?.audioIsActived = true
        audioIsActived = true
        answerCallWithCondition()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("didDeactivate audioSession")
        call?.audioIsActived = false
        audioIsActived = false
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        print("CXSetGroupCallAction")
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("CXPlayDTMFCallAction")
        
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("timedOutPerforming")
        
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
