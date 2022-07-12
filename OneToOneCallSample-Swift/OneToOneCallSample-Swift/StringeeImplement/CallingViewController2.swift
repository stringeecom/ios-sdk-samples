//
//  CallingViewController.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import UIKit
import MediaPlayer

class CallingViewController2: UIViewController {

    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbStatus: UILabel!
    @IBOutlet weak var ivQuality: UIImageView!
    @IBOutlet weak var btMute: UIButton!
    @IBOutlet weak var btSpeaker: UIButton!
    @IBOutlet weak var btEnd: UIButton!
    @IBOutlet weak var btReject: UIButton!
    @IBOutlet weak var btAnswer: UIButton!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet weak var localView: UIView!

    var callControl: CallControl!
    var call: StringeeCall2!

    var callTimer: Timer?
    lazy var timeCounter = TimeCounter()

    var timeoutTimer: Timer?
    var callInterval: Int = 0
    
    // Handle Audio Ouput
    var mpVolumeView: MPVolumeView!
    var airplayRouteButton: UIButton?
    var mediaFirstTimeConnected = false

    // MARK: - Init
    init(control: CallControl, call: StringeeCall2?) {
        super.init(nibName: "CallingViewController2", bundle: nil)
        self.callControl = control
        self.call = call
        call?.delegate = self
        InstanceManager.shared.callingVC2 = self

        // Lưu thông tin vào call control
        if let call = call {
            self.callControl.isIncoming = call.isIncomingCall
            self.callControl.isVideo = call.isVideoCall
            self.callControl.from = call.from
            self.callControl.to = call.to
            self.callControl.username = call.fromAlias
            self.callControl.isAppToPhone = call.callType == .callIn || call.callType == .callOut
        }

        // if call's type is video then route audio to speaker
//        StringeeAudioManager.instance()?.setLoudspeaker(self.callControl.isVideo)
//        self.callControl.isSpeaker = self.callControl.isVideo
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
        NotificationCenter.default.addObserver(self, selector: #selector(CallingViewController2.handleSessionRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)

        // UI
        setupUI()

        // Check timeout for call
        timeoutTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(CallingViewController2.checkCallTimeout), userInfo: nil, repeats: true)
        RunLoop.current.add(timeoutTimer!, forMode: .default)

        if call == nil {
            call = StringeeCall2(stringeeClient: StringeeImplement.shared.stringeeClient, from: callControl.from, to: callControl.to)
            call.delegate = self
            call.isVideoCall = callControl.isVideo

            call.make { [weak self] (status, code, message, data) in
                guard let self = self else { return }
                if (!status) {
                    self.endCallAndDismis()
                }
            }
        } else {
            call.initAnswer()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (airplayRouteButton == nil) {
            mpVolumeView = MPVolumeView(frame: self.view.bounds)
            mpVolumeView.showsRouteButton = false
            mpVolumeView.showsVolumeSlider = false
            mpVolumeView.isUserInteractionEnabled = false
            self.view.addSubview(mpVolumeView)
            airplayRouteButton = mpVolumeView.subviews.filter { $0 is UIButton }.first as? UIButton
        }
    }

    // MARK: - Outlet Actions

    @IBAction func endTapped(_ sender: Any) {
        call.hangup { (status, code, message) in
            if (!status) {
                self.endCallAndDismis()
            }
        }
    }

    @IBAction func rejectTapped(_ sender: Any) {
        call.reject { (status, code, message) in
            if (!status) {
                self.endCallAndDismis()
            }
        }
    }

    @IBAction func answerTapped(_ sender: Any) {
        call.answer { (status, code, message) in
            if (!status) {
                self.endCallAndDismis()
            }
        }
        callControl.signalingState = .answered
        updateScreen()
    }

    @IBAction func muteTapped(_ sender: Any) {
        if call == nil { return }

        callControl.isMute = !callControl.isMute
        call.mute(callControl.isMute)
        let imageName = callControl.isMute ? "icon_mute_selected" : "icon_mute"
        btMute.setBackgroundImage(UIImage(named: imageName), for: .normal)
    }

    @IBAction func speakerTapped(_ sender: Any) {
        let isBluetoothConnected = isBluetoothConnected()
        if (isBluetoothConnected) {
            airplayRouteButton?.sendActions(for: .touchUpInside)
        } else {
            var imageName = ""
            if (callControl.audioOutputMode == .iphone) {
                callControl.audioOutputMode = .speaker
                StringeeAudioManager.instance()?.setLoudspeaker(true)
                imageName = "icon_speaker_selected"
            } else {
                callControl.audioOutputMode = .iphone
                StringeeAudioManager.instance()?.setLoudspeaker(false)
                imageName = "icon_speaker"
            }
            btSpeaker.setBackgroundImage(UIImage(named: imageName), for: .normal)
        }
    }

    // MARK: - Public Actions

    func endCallAndDismis(description: String = "Call ended") {
        DispatchQueue.main.async {
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
            self.view.isUserInteractionEnabled = false
            self.lbStatus.text = description

            // Ngừng timer
            self.stopCallTimer()
            self.stopTimeoutTimer()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                self.dismiss(animated: true, completion: nil)
                InstanceManager.shared.callingVC2 = nil
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
            callTimer = Timer(timeInterval: 1, target: self, selector: #selector(CallingViewController2.timeTick(timer:)), userInfo: nil, repeats: true)
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
                call.reject { (status, code, message) in
                    if (!status) {
                        self.endCallAndDismis()
                    }
                }
            } else {
                call.hangup { (status, code, message) in
                    if (!status) {
                        self.endCallAndDismis()
                    }
                }
            }
        }
    }
}

extension CallingViewController2: StringeeCall2Delegate {
    func didChangeSignalingState2(_ stringeeCall2: StringeeCall2!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        print("didChangeSignalingState2 \(signalingState.rawValue)")
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

    func didChangeMediaState2(_ stringeeCall2: StringeeCall2!, mediaState: MediaState) {
        print("didChangeMediaState2 \(mediaState.rawValue)")
        DispatchQueue.main.async {
            switch mediaState {
            case .connected:
                self.callControl.mediaState = mediaState
                self.lbStatus.text = self.callControl.isIncoming ? "Incoming Call" : "Outgoing Call"
                self.startCallTimer()
                
                // if call's type is video then route audio to speaker
                if self.callControl.isVideo && !self.mediaFirstTimeConnected {
                    self.mediaFirstTimeConnected = !self.mediaFirstTimeConnected
                    self.routeToSpeakerIfNeeded()
                }
            case .disconnected:
                break
            @unknown default:
                break
            }
        }
    }

    func didReceiveLocalStream2(_ stringeeCall2: StringeeCall2!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            stringeeCall2.localVideoView.frame = CGRect(origin: .zero, size: self.localView.frame.size)
            self.localView.addSubview(stringeeCall2.localVideoView)
        }
    }

    func didReceiveRemoteStream2(_ stringeeCall2: StringeeCall2!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            stringeeCall2.remoteVideoView.frame = CGRect(origin: .zero, size: self.remoteView.frame.size)
            self.remoteView.addSubview(stringeeCall2.remoteVideoView)
        }
    }

    func didHandle(onAnotherDevice2 stringeeCall2: StringeeCall2!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        if signalingState == .answered || signalingState == .busy || signalingState == .ended {
            endCallAndDismis(description: "The call is handled on another device")
        }
    }
}

// MARK: - Handle Audio Output

extension CallingViewController2 {
    @objc private func handleSessionRouteChange() {
        DispatchQueue.main.async {
            let route = AVAudioSession.sharedInstance().currentRoute
            if let portDes = route.outputs.first {
                var imageName = ""
                if (portDes.portType == .builtInSpeaker) {
                    self.callControl.audioOutputMode = .speaker
                    imageName = "icon_speaker_selected"
                } else if (portDes.portType == .headphones || portDes.portType == .builtInReceiver) {
                    self.callControl.audioOutputMode = .iphone
                    imageName = "icon_speaker"
                } else {
                    self.callControl.audioOutputMode = .bluetooth
                    imageName = "ic-bluetooth"
                }
                
                self.btSpeaker.setBackgroundImage(UIImage(named: imageName), for: .normal)
            }
        }
    }
    
    private func routeToSpeakerIfNeeded() {
        DispatchQueue.main.async {
            let route = AVAudioSession.sharedInstance().currentRoute
            if let portDes = route.outputs.first {
                // if headphone is not plugged in and bluetooth is not connected then route audio to speaker in case call's type is video
                if portDes.portType != .headphones && !self.isBluetoothConnected() {
                    StringeeAudioManager.instance()?.setLoudspeaker(true)
                    self.callControl.audioOutputMode = .speaker
                }
            }
        }
    }
    
    // Check if device is connected to any bluetooth device or not
    func isBluetoothConnected() -> Bool {
        guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else {
            return false
        }
        
        for availableInput in availableInputs {
            if availableInput.portType == .bluetoothHFP || availableInput.portType == .bluetoothLE || availableInput.portType == .bluetoothA2DP {
                return true
            }
        }
        
        return false
    }
}


