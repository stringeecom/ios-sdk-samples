//
//  CallingViewController.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import UIKit

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
    var isSpeaker = false
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

class CallingViewController: UIViewController {
    
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbStatus: UILabel!
    @IBOutlet weak var ivQuality: UIImageView!
    @IBOutlet weak var btMute: UIButton!
    @IBOutlet weak var btSpeaker: UIButton!
    @IBOutlet weak var btEnd: UIButton!
    @IBOutlet weak var btReject: UIButton!
    @IBOutlet weak var btAnswer: UIButton!
    @IBOutlet weak var blurView: UIView!
    
    var callControl: CallControl!
    var call: StringeeCall!
    
    var callTimer: Timer?
    lazy var timeCounter = TimeCounter()
    
    var timeoutTimer: Timer?
    var callInterval: Int = 0
    
    // MARK: - Init
    init(control: CallControl, call: StringeeCall?) {
        super.init(nibName: "CallingViewController", bundle: nil)
        self.callControl = control
        self.call = call
        call?.delegate = self
        InstanceManager.shared.callingVC = self
        
        // Lưu thông tin vào call control
        if let call = call {
            self.callControl.isIncoming = call.isIncomingCall
            self.callControl.isVideo = call.isVideoCall
            self.callControl.from = call.from
            self.callControl.to = call.to
            self.callControl.username = call.fromAlias
            self.callControl.isAppToPhone = call.callType == .callIn || call.callType == .callOut
        }
        
        // Nếu là videoCall thì cho ra loa ngoài
        if self.callControl.isVideo {
            StringeeAudioManager.instance()?.setLoudspeaker(true)
            self.callControl.isSpeaker = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(CallingViewController.handleSessionRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        
        // UI
        setupUI()
        
        // Check timeout for call
        timeoutTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(CallingViewController.checkCallTimeout), userInfo: nil, repeats: true)
        RunLoop.current.add(timeoutTimer!, forMode: .default)
        
        if call == nil {
            call = StringeeCall(stringeeClient: StringeeImplement.shared.stringeeClient, from: callControl.from, to: callControl.to)
            call.delegate = self
            call.isVideoCall = callControl.isVideo
            
            call.make { [weak self] (status, code, message, data) in
                guard let self = self else { return }
                if (status) {
                    // Thành công => start CallKit
                    CallManager.shared.startCall(phone: self.callControl.to, calleeName: self.callControl.displayName, isVideo: self.callControl.isVideo, stringeCall: self.call)
                } else {
                    // Thất bại -> dismissview
                    self.endCallAndDismis()
                }
            }
        }
    }
    
    // MARK: - Outlet Actions
    
    @IBAction func endTapped(_ sender: Any) {
        CallManager.shared.hangup()
    }
    
    @IBAction func rejectTapped(_ sender: Any) {
        CallManager.shared.reject()
    }
    
    @IBAction func answerTapped(_ sender: Any) {
        if #available(iOS 14, *) {
            CallManager.shared.answerCallkitCall()
        } else {
            CallManager.shared.answer()
        }
    }
    
    @IBAction func muteTapped(_ sender: Any) {
        CallManager.shared.mute()
        let imageName = callControl.isMute ? "icon_mute_selected" : "icon_mute"
        btMute.setBackgroundImage(UIImage(named: imageName), for: .normal)
    }
    
    @IBAction func speakerTapped(_ sender: Any) {
        callControl.isSpeaker = !callControl.isSpeaker
        StringeeAudioManager.instance()?.setLoudspeaker(callControl.isSpeaker)
        let imageName = callControl.isSpeaker ? "icon_speaker_selected" : "icon_speaker"
        btSpeaker.setBackgroundImage(UIImage(named: imageName), for: .normal)
    }
    
    // MARK: - Public Actions
    
    func endCallAndDismis(description: String = "Call ended") {
        DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
            self.view.isUserInteractionEnabled = false
            self.lbStatus.text = description
            
            // End callkit
            CallManager.shared.endCall()

            // Ngừng timer
            self.stopCallTimer()
            self.stopTimeoutTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                self.dismiss(animated: true, completion: nil)
                InstanceManager.shared.callingVC = nil
            })
        }
    }
    
    func updateScreen() {
        DispatchQueue.main.async {
            let screenType = self.screenType()
            switch screenType {
            case .incoming:
                self.btReject.isHidden = false
                self.btAnswer.isHidden = false
                self.btEnd.isHidden = true
                break
            case .outgoing:
                self.btReject.isHidden = true
                self.btAnswer.isHidden = true
                self.btEnd.isHidden = false
                break
            case .calling:
                self.btReject.isHidden = true
                self.btAnswer.isHidden = true
                self.btEnd.isHidden = false
                break
            }
        }
    }
    // MARK: - Private Actions
    
    private func screenType() -> CallScreenType {
        var screenType: CallScreenType!
        if (callControl.signalingState == .answered) {
            screenType = .calling
        } else {
            screenType = callControl.isIncoming ? .incoming : .outgoing
        }
        
        return screenType
    }
    
    private func setupUI() {
        UIDevice.current.isProximityMonitoringEnabled = true
        UIApplication.shared.isIdleTimerDisabled = callControl.isVideo
        
        self.btAnswer.isEnabled = false
        self.btReject.isEnabled = false
        
        // Fill data
        self.lbStatus.text = callControl.isIncoming ? "Incoming Call" : "Outgoing Call"
        self.lbName.text = callControl.displayName
        
        updateScreen()
    }
    
    // MARK: - Timer
    
    private func startCallTimer() {
        if callControl.signalingState != .answered || callControl.mediaState != .connected {
            return
        }
        
        if callTimer == nil {
            // Bắt đầu đếm giây
            callTimer = Timer(timeInterval: 1, target: self, selector: #selector(CallingViewController.timeTick(timer:)), userInfo: nil, repeats: true)
            RunLoop.current.add(callTimer!, forMode: .default)
            callTimer?.fire()
            
            // => Ko check timeout nữa
            self.stopTimeoutTimer()
        }
    }
    
    @objc private func timeTick(timer: Timer) {
        let timeNow = timeCounter.timeNow()
        self.lbStatus.text = timeNow
    }
    
    private func stopCallTimer() {
        CFRunLoopStop(CFRunLoopGetCurrent())
        callTimer?.invalidate()
        callTimer = nil
    }
    
    private func stopTimeoutTimer() {
        CFRunLoopStop(CFRunLoopGetCurrent())
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    @objc private func checkCallTimeout() {
        print("checkCallTimeout")
        callInterval += 10
        if callInterval > 60 && callTimer == nil {
            if callControl.isIncoming {
                CallManager.shared.reject()
            } else {
                CallManager.shared.hangup()
            }
        }
    }
}

extension CallingViewController: StringeeCallDelegate {
    func didChangeSignalingState(_ stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        print("didChangeSignalingState \(signalingState.rawValue)")
        callControl.signalingState = signalingState
        DispatchQueue.main.async {
            switch signalingState {
            case .calling:
                self.lbStatus.text = "Calling..."
            case .ringing:
                self.lbStatus.text = "Ringing..."
            case .answered:
                self.callControl.signalingState = .answered
                self.updateScreen()
                self.startCallTimer()
            case .ended:
                self.endCallAndDismis()
            case .busy:
                self.endCallAndDismis(description: "Busy")
            @unknown default:
                break
            }
        }
    }
    
    func didChangeMediaState(_ stringeeCall: StringeeCall!, mediaState: MediaState) {
        print("didChangeMediaState \(mediaState.rawValue)")
        DispatchQueue.main.async {
            switch mediaState {
            case .connected:
                self.callControl.mediaState = mediaState
                self.lbStatus.text = self.callControl.isIncoming ? "Incoming Call" : "Outgoing Call"
                self.startCallTimer()
            case .disconnected:
                break
            @unknown default:
                break
            }
        }
    }
    
    func didHandle(onAnotherDevice stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        if signalingState == .answered {
            endCallAndDismis(description: "The call is handled on another device")
        }
    }
}

// MARK: - Notifications

extension CallingViewController {
    @objc private func handleSessionRouteChange() {
        DispatchQueue.main.async {
            let route = AVAudioSession.sharedInstance().currentRoute
            if let portDes = route.outputs.first {
                self.callControl.isSpeaker = portDes.portType == .builtInSpeaker
                let imageName = self.callControl.isSpeaker ? "icon_speaker_selected" : "icon_speaker"
                self.btSpeaker.setBackgroundImage(UIImage(named: imageName), for: .normal)
            }
        }
    }
}

