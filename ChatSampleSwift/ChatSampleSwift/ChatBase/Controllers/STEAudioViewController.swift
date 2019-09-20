//
//  STEAudioViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 5/13/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEAudioViewControllerPadding: CGFloat = 20
let STEAudioViewControllerMargin: CGFloat = 20

protocol STEAudioViewControllerDelegate: AnyObject {
    func audioControllerSendAudio(filePath: URL)
}

class STEAudioViewController: UIViewController {
    
    let lbDescription: UILabel = {
        let label = UILabel()
        label.text = "Bấm nút để bắt đầu ghi âm"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = STEColor.blue
        return label
    }()
    
    let lbTime: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.textColor = STEColor.blue
        return label
    }()
    
    let btRecord: STERecordButton = {
        let recordButton = STERecordButton()
        recordButton.isEnabled = false
        return recordButton
    }()
    
    var audioRecorder: AVAudioRecorder?
    var recordingAudioSession: AVAudioSession!
    var timer: Timer?
    weak var delegate: STEAudioViewControllerDelegate?
    
    override func loadView() {
        super.loadView()
        
        self.view.addSubview(self.lbDescription)
        self.view.addSubview(self.lbTime)
        self.view.addSubview(self.btRecord)
        
        lbDescription.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(STEAudioViewControllerPadding)
            make.left.equalTo(self.view).offset(STEAudioViewControllerPadding)
            make.right.equalTo(self.view).offset(-STEAudioViewControllerPadding)
        }
        
        lbTime.snp.makeConstraints { (make) in
            make.top.equalTo(lbDescription.snp.bottom).offset(STEAudioViewControllerMargin)
            make.left.equalTo(self.view).offset(STEAudioViewControllerPadding)
            make.right.equalTo(self.view).offset(-STEAudioViewControllerPadding)
        }
        
        btRecord.snp.makeConstraints { (make) in
            make.top.equalTo(lbTime.snp.bottom).offset(STEAudioViewControllerMargin)
            make.centerX.equalTo(self.view)
        }
        
        btRecord.addTarget(self, action: #selector(STEAudioViewController.handleRecordTapped), for: .touchUpInside)
    }
    
    deinit {
        stopRecording()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        recordingAudioSession = AVAudioSession.sharedInstance()
        
        do {
            if #available(iOS 10.0, *) {
                try recordingAudioSession.setCategory(.playAndRecord, mode: .default)
            } else {
                try recordingAudioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            }
            try recordingAudioSession.setActive(true)
            recordingAudioSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.btRecord.isEnabled = true
                    } else {
                        // failed to record!
                        self.stopRecording()
                    }
                }
            }
        } catch {
            // failed to record!
            self.stopRecording()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(STEAudioViewController.handleAudioRecorderEndInterruption), name: AVAudioSession.interruptionNotification, object: self.audioRecorder)
    }
    
    @objc private func handleRecordTapped() {
        print("handleRecordTapped")
        if self.audioRecorder != nil {
            lbDescription.text = "Bấm nút để bắt đầu ghi âm"
            stopRecording()
        } else {
            lbDescription.text = "Bấm nút để gửi file ghi âm"
            startRecording()
        }
    }
    
    private func startRecording() {
        // Tạo đường dẫn tạm thời của file output
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.m4a")
        
        let recordingSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                 AVSampleRateKey: 12000,
                                 AVNumberOfChannelsKey: 1,
                                 AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
                                 ]

        do {
            try audioRecorder = AVAudioRecorder(url: filePath, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(STEAudioViewController.countTime), userInfo: nil, repeats: true)
            timer?.fire()
        } catch {
            print("\(error.localizedDescription)")
            stopRecording()
        }
        
    }
    
    private func stopRecording() {
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        self.timer?.invalidate()
        self.timer = nil
        self.lbTime.text = "00:00"
    }
    
    @objc private func countTime() {
        if self.audioRecorder == nil { return }
        let currentTime = self.audioRecorder?.currentTime ?? 0
        DispatchQueue.main.async {
            self.lbTime.text = STEStringToDisplayFrom(duration: currentTime)
        }
    }
}

extension STEAudioViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopRecording()
        self.delegate?.audioControllerSendAudio(filePath: recorder.url)
        dismiss(animated: true, completion: nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        stopRecording()
    }
    
    @objc private func handleAudioRecorderEndInterruption() {
        stopRecording()
    }
    
}
