//
//  STEVideoCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEVideoCollectionViewCell: STEBaseCollectionViewCell {
    
    var maskBubbleView: UIImageView?

    let ivPhoto: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    let durationView: UIView = {
        let view = UIView()
        view.backgroundColor = STEColor.darkGray
        view.layer.cornerRadius = STEMessageStatusViewCornerRadius
        view.clipsToBounds = true
        return view
    }()
    
    let lbDuration: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = STEMessageStatusViewLabelTimeFont
        return label
    }()
    
    let btPlay: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play_icon"), for: .normal)
        button.isHidden = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
//        contentView.backgroundColor = .clear
//        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
//        bubbleView.clipsToBounds = true
        
        bubbleView.addSubview(ivPhoto)
        bubbleView.addSubview(statusView)
        durationView.addSubview(lbDuration)
        bubbleView.addSubview(durationView)
        bubbleView.addSubview(btPlay)
        bubbleView.progressView.delegate = self
        
        btPlay.addTarget(self, action: #selector(STEVideoCollectionViewCell.handlePlayTapped), for: .touchUpInside)

//        ivPhoto.layer.cornerRadius = STEMessageBubbleViewCornerRadius
        ivPhoto.clipsToBounds = true
        ivPhoto.sd_imageTransition = .fade

        // Layout
        ivPhoto.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        
        statusView.snp.makeConstraints { (make) in
            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
        
        lbDuration.snp.makeConstraints { (make) in
            make.edges.equalTo(durationView).inset(UIEdgeInsets(top: STEMessageStatusViewVerticalPadding, left: STEMessageStatusViewHorizontalPadding, bottom: STEMessageStatusViewVerticalPadding, right: STEMessageStatusViewHorizontalPadding))
        }
        
        durationView.snp.makeConstraints { (make) in
            make.left.equalTo(bubbleView.snp.left).offset(STEMessageBubbleViewHorizontalPadding)
            make.top.equalTo(bubbleView.snp.top).offset(STEMessageBubbleViewVerticalPadding)
        }
        
        btPlay.snp.makeConstraints { (make) in
            make.center.equalTo(bubbleView.snp.center)
            make.width.equalTo(bubbleView.progressView.snp.width)
            make.height.equalTo(bubbleView.progressView.snp.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskBubbleView?.frame = ivPhoto.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.bubbleView.progressView.isHidden = true
        self.ivPhoto.image = nil
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
        guard let videoMsg = message as? StringeeVideoMessage else { return }

        if let strThumbnail = videoMsg.thumbnailUrl, strThumbnail.count > 0, let url = URL(string: strThumbnail) {
            ivPhoto.sd_setImage(with: url, completed: nil)
            lbDuration.text = STEStringToDisplayFrom(duration: videoMsg.duration / 1000)
        }
        statusView.update(status: videoMsg.status, timeStamp: videoMsg.created, tintColor: .white)

        // Check xem có nên show button download
        let shouldShowDownload = videoMsg.transferStatus == .readyForDownload
        self.bubbleView.progressView.downloadButton.isHidden = !shouldShowDownload
        self.bubbleView.progressView.isHidden = !(shouldShowDownload == true)
        
        // Nếu đã tải được thì cho phép play
        if let filePath = videoMsg.filePath, filePath.count > 0, videoMsg.transferStatus == .complete {
            btPlay.isHidden = false
        } else {
            btPlay.isHidden = true
        }
        
        // Trường hợp đang transfer file (up/down) => update progress
        videoMsg.progress?.delegate = self
        if videoMsg.filePath != nil && (videoMsg.transferStatus == .awaitingUpload || videoMsg.transferStatus == .downloading || videoMsg.transferStatus == .uploading) {
            self.bubbleView.progressView.setProgress(CGFloat(videoMsg.progress.fractionCompleted), animated: true)
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
    
    @objc private func handlePlayTapped() {
        print("handlePlayTapped")
        guard let videoMsg = self.message as? StringeeVideoMessage, let filePath = videoMsg.filePath, filePath.count > 0 else { return }
        
        let url = URL(fileURLWithPath: filePath)
        self.delegate?.didTapPlayVideo(cell: self, url: url)
    }
    
}

// MARK: - STEProgressViewDelegate

extension STEVideoCollectionViewCell: STEProgressViewDelegate {
    func didTapDownloadButton(view: STEProgressView) {
        print("didTapDownloadButton")
        self.bubbleView.progressView.downloadButton.isHidden = true
        self.message?.downloadContent()
    }
}

// MARK: - StringeeProgress Delegate

extension STEVideoCollectionViewCell: StringeeProgressDelegate {
    func progressDidChange(_ progress: StringeeProgress!) {
        print("progressDidChange")
        if progress.delegate == nil || (progress.delegate as? STEVideoCollectionViewCell) != self {
            return
        }
        
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
        }
    }
    
    func transferCompleted(_ progress: StringeeProgress!) {
        print("transferCompleted")
        if progress.delegate == nil || (progress.delegate as? STEVideoCollectionViewCell) != self {
            return
        }
        progress.delegate = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.bubbleView.progressView.setProgress(1, animated: true)
            self.btPlay.isHidden = false
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

class STEVideoIncomingMessageCollectionViewCell: STEVideoCollectionViewCell {
    
    static let identifier = "STEVideoIncomingMessageCollectionViewCell"
    
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
        ivPhoto.backgroundColor = STEColor.incomingBackground
//        bubbleView.backgroundColor = STEColor.incomingBackground
        
        maskBubbleView = UIImageView(image: STEIncomingImage)
        ivPhoto.mask = maskBubbleView
    }
    
//    override func present(message: StringeeMessage, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
//        super.present(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
    
//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.incomingBackground, borderColor: STEColor.incomingBorder, isOutgoing: false)
//
//            let borderLayer = CAShapeLayer()
//            borderLayer.path = bubbleLayer.path
//            borderLayer.fillColor = nil
//            borderLayer.strokeColor = STEColor.incomingBorder.cgColor
//
//            DispatchQueue.main.async {
//                self.ivPhoto.layer.mask = bubbleLayer
//                self.ivPhoto.layer.sublayers?.removeAll()
//                self.ivPhoto.layer.addSublayer(borderLayer)
//            }
//        }
//    }
}

class STEVideoOutgoingMessageCollectionViewCell: STEVideoCollectionViewCell {
    
    static let identifier = "STEVideoOutgoingMessageCollectionViewCell"
    
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
        ivPhoto.backgroundColor = STEColor.outgoingBackground
//        bubbleView.backgroundColor = STEColor.outgoingBackground
        
        maskBubbleView = UIImageView(image: STEOutgoingImage)
        ivPhoto.mask = maskBubbleView
    }
    
//    override func present(message: StringeeMessage, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
//        super.present(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
    
//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.outgoingBackground, borderColor: STEColor.outgoingBorder, isOutgoing: true)
//
//            let borderLayer = CAShapeLayer()
//            borderLayer.path = bubbleLayer.path
//            borderLayer.fillColor = nil
//            borderLayer.strokeColor = STEColor.outgoingBorder.cgColor
//
//            DispatchQueue.main.async {
//                self.ivPhoto.layer.mask = bubbleLayer
//                self.ivPhoto.layer.sublayers?.removeAll()
//                self.ivPhoto.layer.addSublayer(borderLayer)
//            }
//        }
        
        
//    }
}

