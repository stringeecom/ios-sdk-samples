//
//  CallingViewController.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import UIKit

class CallingViewController: UIViewController {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var callingConnectStateLabel: UILabel!
    @IBOutlet weak var connectQualityImage: UIImageView!
    
    @IBOutlet weak var optionView: UIView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var muteLabel: UILabel!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var speakerLabel: UILabel!
    
    @IBOutlet weak var endCallButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    @IBOutlet weak var blurView: UIView!
    
    private var callTime: Int = 0
    private var callingTimer: Timer?
    private var reportTimer: Timer?
    
    private var hasConnectedMedia = false
    
    private var isIncomingCall: Bool
    private var displayUserName: String
    
    private var isDismissing = false
    
    init(withUserName name: String, isIncomingCall: Bool) {
        self.isIncomingCall = isIncomingCall
        self.displayUserName = name
        super.init(nibName: "CallingViewController", bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @IBAction func actionCallButtonHandler(_ sender: UIButton) {
        var userAction: UserCallingAcion?
        switch sender {
        case endCallButton, declineButton: userAction = .end
        case acceptButton: answerCall {
                StringeeCallCenter.shared.userAction(.answer)
            }
        case muteButton: userAction = .mute
        case speakerButton: userAction = .speaker
        default: return
        }
        
        guard let action = userAction else { return }
        StringeeCallCenter.shared.userAction(action)
    }
    
    private func setupUI() {
        userNameLabel.text = displayUserName
        endCallButton.isHidden = isIncomingCall
        declineButton.isHidden = !isIncomingCall
        acceptButton.isHidden = !isIncomingCall
    }
    
    private func answerCall(completion: (() -> Void)? = nil) {
        self.declineButton.isHidden = true
        UIView.animate(withDuration: 0.4, animations: {
            self.acceptButton.center = self.endCallButton.center
            self.acceptButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi*3/4)
        }) { _ in
            self.acceptButton.isHidden = true
            self.endCallButton.isHidden = false
            completion?()
        }
    }
    
    private func dismiss(with title: String) {
        callingConnectStateLabel.text = title
        view.isUserInteractionEnabled = false
        blurView.alpha = 0.4
        UIDevice.current.isProximityMonitoringEnabled = false
        
        callingTimer?.invalidate()
        
        isDismissing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.dismiss(animated: true)
        }
    }
}

extension CallingViewController: StringeeCallingVCProtocol {
    func updateUI(with action: UserCallingAcion) {
        guard !isDismissing else { return }
        switch action {
        case .answer: answerCall()
        case .end: dismiss(with: "Kết thúc cuộc gọi")
        case .speaker:
            let isSpeaker = StringeeCallCenter.shared.isSpeaker
            speakerButton.setBackgroundImage(UIImage(named: "\(isSpeaker ? "icon_speaker_selected" : "icon_speaker")"), for: .normal)
        case .mute:
            let isMute = StringeeCallCenter.shared.isMute
            muteButton.setBackgroundImage(UIImage(named: "\(isMute ? "icon_mute_selected" : "icon_mute")"), for: .normal)
        }
    }
    
    func updateUI(for state: SignalingState) {
        DispatchQueue.main.async {
            switch state {
            case .calling:
                self.callingConnectStateLabel.text = "Đang gọi..."
            case .ringing:
                self.callingConnectStateLabel.text = "Đang đổ chuông..."
            case .answered:
                if self.hasConnectedMedia {
                    self.startCountCallTime()
                } else {
                    self.callingConnectStateLabel.text = "Đang kết nối..."
                }
            case .busy:
                self.callingTimer?.invalidate()
                self.updateCallingTimeLabel()
                self.dismiss(with: "Số máy bận")
            case .ended:
                self.callingTimer?.invalidate()
                self.updateCallingTimeLabel()
                self.dismiss(with: "Kết thúc cuộc gọi")
            @unknown default:
                fatalError()
            }
        }
    }
    
    func didChangeMediaState(mediaState: MediaState) {
        DispatchQueue.main.async {
            switch mediaState {
            case .connected:
                self.hasConnectedMedia = true
                self.startCountCallTime()
            case .disconnected:
                break
            @unknown default:
                fatalError()
            }
        }
    }
}

extension CallingViewController {
    private func secondsToHoursMinutesSeconds (seconds: Int) -> (hh: Int, mm: Int, ss: Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    private func updateCallingTimeLabel() {
        let timeComponent = secondsToHoursMinutesSeconds(seconds: callTime)
        var timeString: String
        if timeComponent.hh > 0 {
            timeString = String(format: "%d:%02d:%02d", timeComponent.hh, timeComponent.mm, timeComponent.ss)
        } else {
            timeString = String(format: "%02d:%02d", timeComponent.mm, timeComponent.ss)
        }
        self.callingConnectStateLabel.text = timeString
    }
    
    private func startCountCallTime() {
        guard callingTimer == nil else { return }
        updateCallingTimeLabel()
        callingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            self.callTime += 1
            self.updateCallingTimeLabel()
        })
    }
}
        
        // Tính mạng
//        reportTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
//            guard let self = self else { return }
//            self.stringeeCall.stats { (values) in
//                guard let internetStatus = Reporter.shared.checkAudioQuality(with: values) else { return }
//                DispatchQueue.main.async {
//                    self.connectQualityImage.image = internetStatus.icon
//                }
//            }
//        })
//    }
    

//}
