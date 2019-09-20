//
//  STEAudioCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEAudioCellLabelDurationFont = UIFont.systemFont(ofSize: 11)
let STEAudioCellButtonPlayWidth: CGFloat = 45

class STEAudioCollectionViewCell: STEBaseCollectionViewCell {
    
    let ivBubble: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    let btPlay: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = STEAudioCellButtonPlayWidth / 2
        button.clipsToBounds = true
        button.setImage(UIImage(named: "TempAudioPreviewPlay"), for: .normal)
        button.backgroundColor = STEColor.green
        return button
    }()
    
    let sliderTrack: UISlider = {
        let slider = UISlider()
        slider.setThumbImage(UIImage(named: "slider_thumb"), for: .normal)
        slider.minimumTrackTintColor = STEColor.green
        return slider
    }()
    
    let lbDuration: UILabel = {
        let label = UILabel()
        label.text = "00:05"
        label.font = STEAudioCellLabelDurationFont
        label.textColor = STEColor.green
        return label
    }()
    
    var isSliding = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func commonInit() {
//        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
//        bubbleView.clipsToBounds = true
        
        bubbleView.addSubview(ivBubble)
        bubbleView.addSubview(btPlay)
        bubbleView.addSubview(sliderTrack)
        bubbleView.addSubview(lbDuration)
        bubbleView.addSubview(statusView)
        statusView.backgroundColor = .clear
        
        // Layout
        ivBubble.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        btPlay.snp.makeConstraints { (make) in
            make.top.equalTo(bubbleView).offset(STEMessageBubbleViewVerticalPadding)
            make.left.equalTo(bubbleView).offset(STEMessageBubbleViewHorizontalPadding)
            make.width.equalTo(btPlay.snp.height)
            make.width.equalTo(STEAudioCellButtonPlayWidth)
        }
        
        sliderTrack.snp.makeConstraints { (make) in
            make.centerY.equalTo(btPlay)
            make.left.equalTo(btPlay.snp.right).offset(STEMessageBubbleViewHorizontalPadding)
            make.right.equalTo(bubbleView.snp.right).offset(-STEMessageBubbleViewHorizontalPadding)
        }
        
        lbDuration.snp.makeConstraints { (make) in
            make.left.equalTo(sliderTrack)
            make.top.equalTo(sliderTrack.snp.bottom).offset(STEMessageBubbleViewVerticalPadding)
        }
        
        statusView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
        
        bubbleView.progressView.delegate = self
        btPlay.addTarget(self, action: #selector(STEAudioCollectionViewCell.handlePlayTapped), for: .touchUpInside)
        sliderTrack.addTarget(self, action: #selector(STEAudioCollectionViewCell.audioSliderValueChanged(sender:forEvent:)), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(STEAudioCollectionViewCell.handleAudioTracking(notification:)), name: Notification.Name.STEPlayerManagerTrackingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(STEAudioCollectionViewCell.handleAudioItemEnded(notification:)), name: Notification.Name.STEPlayerManagerEndItemNotification, object: nil)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSliding = false
        self.bubbleView.progressView.isHidden = true
    }
    
    // MARK: - Overide Message Presenting
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)

        updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).width)
        self.shouldDisplayAvatar(should: shouldDisplayAvatar)
        self.shouldDisplayMsgStatus(should: shouldDisplayMsgStatus)
        self.shouldDisplaySender(should: shouldDisplaySender)
        
        // Data
        guard let audioMsg = message as? StringeeAudioMessage else { return }
        
        let durationToSeconds = (audioMsg.duration / 1000.0).rounded(.toNearestOrAwayFromZero)
        self.lbDuration.text = STEStringToDisplayFrom(duration: durationToSeconds)
        
        // Check xem có nên show button download
        let shouldShowDownload = audioMsg.transferStatus == .readyForDownload
        self.bubbleView.progressView.downloadButton.isHidden = !shouldShowDownload
        self.bubbleView.progressView.isHidden = !(shouldShowDownload == true)
        
        // Nếu đã tải được thì cho phép play
        if let filePath = audioMsg.filePath, filePath.count > 0, audioMsg.transferStatus == .complete {
            btPlay.isEnabled = true
            sliderTrack.isEnabled = true
        } else {
            btPlay.isEnabled = false
            sliderTrack.isEnabled = false
        }
        self.changePlayButtonImage(isStop: true)
        
        // Trường hợp đang transfer file (up/down) => update progress
        audioMsg.progress?.delegate = self
        if audioMsg.filePath != nil && (audioMsg.transferStatus == .awaitingUpload || audioMsg.transferStatus == .downloading || audioMsg.transferStatus == .uploading) {
            self.bubbleView.progressView.setProgress(CGFloat(audioMsg.progress.fractionCompleted), animated: true)
        }
        
        // Cập nhật trạng media nếu đang play hoặc ngược lại
        if let filePath = audioMsg.filePath, filePath.count > 0, filePath == STEPlayerManager.shared.currentItemId {
            let durationToSeconds = (audioMsg.duration / 1000.0).rounded(.toNearestOrAwayFromZero)
            self.lbDuration.text = STEStringToDisplayFrom(duration: durationToSeconds - Double(STEPlayerManager.shared.currentTime()))
            
            if STEPlayerManager.shared.currentTime() != 0 {
                let value: Float = Float(STEPlayerManager.shared.currentTime()) / Float(durationToSeconds)
                self.sliderTrack.value = value
            }
            self.changePlayButtonImage(isStop: !STEPlayerManager.shared.isPlaying())
        }
    }
    
    override func shouldDisplayAvatar(should: Bool) {
        displayAvatar(should)
    }
    
    override func shouldDisplaySender(should: Bool) {
        if (should) {
        } else {
        }
    }
    
    override func shouldDisplayMsgStatus(should: Bool) {
        statusView.displayMsgStatus(should)
    }
    
    // MARK: - Actions
    
    @objc private func handlePlayTapped() {
        print("handlePlayTapped")
        if let audioMsg = self.message as? StringeeAudioMessage, let filePath = audioMsg.filePath {
            let url = URL(fileURLWithPath: filePath)
            let isPlaying = STEPlayerManager.shared.play(filePath: url)
            self.changePlayButtonImage(isStop: !isPlaying)
        }
    }
    
    @objc private func handleAudioTracking(notification: Notification) {
        guard let identifier = notification.userInfo?[STEPlayerManagerIdKey] as? String, identifier.count > 0, let audioMsg = self.message as? StringeeAudioMessage, let filePath = audioMsg.filePath, identifier == filePath else {
            return
        }
        
        if self.isSliding { return }

        DispatchQueue.main.async {
            let durationToSeconds = (audioMsg.duration / 1000.0).rounded(.toNearestOrAwayFromZero)
            self.lbDuration.text = STEStringToDisplayFrom(duration: durationToSeconds - Double(STEPlayerManager.shared.currentTime()))
            
            if STEPlayerManager.shared.currentTime() != 0 {
                let value: Float = Float(STEPlayerManager.shared.currentTime()) / Float(durationToSeconds)
                self.sliderTrack.value = value
            }
        }
    }
    
    @objc private func handleAudioItemEnded(notification: Notification) {
        guard let identifier = notification.userInfo?[STEPlayerManagerIdKey] as? String, identifier.count > 0, let audioMsg = self.message as? StringeeAudioMessage, let filePath = audioMsg.filePath, identifier == filePath else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let durationToSeconds = (audioMsg.duration / 1000.0).rounded(.toNearestOrAwayFromZero)
            self.lbDuration.text = STEStringToDisplayFrom(duration: durationToSeconds)
            self.sliderTrack.value = 0
            self.changePlayButtonImage(isStop: true)
        }
    }
    
    private func changePlayButtonImage(isStop: Bool) {
        let imageName = isStop ? "TempAudioPreviewPlay" : "TempAudioPreviewPause"
        btPlay.setImage(UIImage(named: imageName), for: .normal)
    }

    @objc private func audioSliderValueChanged(sender: Any, forEvent event: UIEvent) {
        print("audioSliderValueChanged")
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                isSliding = true
                break
            case .moved:
                break
            case .ended:
                guard let audioMsg = self.message as? StringeeAudioMessage, let filePath = audioMsg.filePath, filePath == STEPlayerManager.shared.currentItemId else {
                    isSliding = false
                    return
                }
                
                let durationToSeconds = (audioMsg.duration / 1000.0).rounded(.toNearestOrAwayFromZero)
                STEPlayerManager.shared.seekTo(time: sliderTrack.value, duration: durationToSeconds) { (status) in
                    self.isSliding = false
                }

                break
            default:
                break
            }
        }
    }
}

// MARK: - STEProgressViewDelegate

extension STEAudioCollectionViewCell: STEProgressViewDelegate {
    func didTapDownloadButton(view: STEProgressView) {
        print("didTapDownloadButton")
        self.bubbleView.progressView.downloadButton.isHidden = true
        self.message?.downloadContent()
    }
}

// MARK: - StringeeProgress Delegate

extension STEAudioCollectionViewCell: StringeeProgressDelegate {
    func progressDidChange(_ progress: StringeeProgress!) {
        print("progressDidChange")
        if progress.delegate == nil || (progress.delegate as? STEAudioCollectionViewCell) != self {
            return
        }
        
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
        }
    }
    
    func transferCompleted(_ progress: StringeeProgress!) {
        print("transferCompleted")
        if progress.delegate == nil || (progress.delegate as? STEAudioCollectionViewCell) != self {
            return
        }
        progress.delegate = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.bubbleView.progressView.setProgress(1, animated: true)
            self.btPlay.isEnabled = true
        }
    }
    
    func transferFailed(_ progress: StringeeProgress!, error: NSErrorPointer) {
        print("transferFailed")
        progress.delegate = nil
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(1, animated: true)
        }
    }
}

class STEAudioIncomingMessageCollectionViewCell: STEAudioCollectionViewCell {
    
    static let identifier = "STEAudioIncomingMessageCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        incomingCommonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        incomingCommonInit()
    }
    
    private func incomingCommonInit() {
        configureCellForMode(mode: .incoming)
        btPlay.backgroundColor = STEColor.incomingTheme
        sliderTrack.minimumTrackTintColor = STEColor.incomingTheme
        lbDuration.textColor = STEColor.incomingTheme
        statusView.lbTime.textColor = STEColor.incomingTime
        
        self.ivBubble.image = STEIncomingImage
        self.ivBubble.tintColor = STEColor.incomingBackground
    }
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        statusView.update(status: message.status, timeStamp: message.created, tintColor: STEColor.incomingTime)

//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.incomingBackground, borderColor: STEColor.incomingBorder, isOutgoing: false)
//
//            DispatchQueue.main.async {
//                for layer in self.bubbleView.layer.sublayers! {
//                    if layer.isKind(of: CAShapeLayer.self) {
//                        layer.removeFromSuperlayer()
//                        break
//                    }
//                }
//                self.bubbleView.layer.insertSublayer(bubbleLayer, at: 0)
//            }
//        }
    }
}

class STEAudioOutgoingMessageCollectionViewCell: STEAudioCollectionViewCell {
    
    static let identifier = "STEAudioOutgoingMessageCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        outgoingCommonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        outgoingCommonInit()
    }
    
    private func outgoingCommonInit() {
        configureCellForMode(mode: .outgoing)
        btPlay.backgroundColor = STEColor.outgoingTheme
        sliderTrack.minimumTrackTintColor = STEColor.outgoingTheme
        lbDuration.textColor = STEColor.outgoingTheme
        statusView.lbTime.textColor = STEColor.outgoingTheme
        
        self.ivBubble.image = STEOutgoingImage
        self.ivBubble.tintColor = STEColor.outgoingBackground
    }
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        statusView.update(status: message.status, timeStamp: message.created, tintColor: STEColor.outgoingTheme)

//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.outgoingBackground, borderColor: STEColor.outgoingBorder, isOutgoing: true)
//
//            DispatchQueue.main.async {
//                for layer in self.bubbleView.layer.sublayers! {
//                    if layer.isKind(of: CAShapeLayer.self) {
//                        layer.removeFromSuperlayer()
//                        break
//                    }
//                }
//                self.bubbleView.layer.insertSublayer(bubbleLayer, at: 0)
//            }
//        }
    }
}
