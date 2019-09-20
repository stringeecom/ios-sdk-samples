//
//  STEPhotoCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/6/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEPhotoCollectionViewCell: STEBaseCollectionViewCell {
    
    var maskBubbleView: UIImageView?

    let ivPhoto: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .lightGray
        imageView.contentMode = .scaleToFill
        return imageView
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
        bubbleView.progressView.downloadButton.isHidden = true
        
//        ivPhoto.layer.cornerRadius = STEMessageBubbleViewCornerRadius
        ivPhoto.clipsToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(STEPhotoCollectionViewCell.handleImageTapped(sender:)))
        ivPhoto.addGestureRecognizer(tapGesture)
        ivPhoto.isUserInteractionEnabled = true
        ivPhoto.sd_imageTransition = .fade
        
        // Layout
        ivPhoto.snp.makeConstraints { (make) in
//            make.edges.equalTo(bubbleView).inset(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
            make.edges.equalTo(bubbleView)
        }
        
        statusView.snp.makeConstraints { (make) in
            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskBubbleView?.frame = ivPhoto.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.ivPhoto.image = nil
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
        
        statusView.update(status: message.status, timeStamp: message.created, tintColor: .white)
        
        // Present
        if let photoMsg = self.message as? StringeePhotoMessage {
            
            // Update progress nếu đang upload file lên
            photoMsg.progress?.delegate = self
            if let filePath = photoMsg.filePath, filePath.count > 0, (photoMsg.transferStatus == .awaitingUpload || photoMsg.transferStatus == .uploading) {
                self.bubbleView.progressView.setProgress(CGFloat(photoMsg.progress?.fractionCompleted ?? 0), animated: true)
            }
            
            STEBaseCollectionViewCell.messageProcessingQueue.async {
                if let filePath = photoMsg.filePath, filePath.count > 0, let image = UIImage(contentsOfFile: filePath) {
                    DispatchQueue.main.async {
                        self.ivPhoto.image = image
                    }
                } else if let fileUrl = photoMsg.fileUrl, fileUrl.count > 0, let url = URL(string: fileUrl) {
                    weak var weakMsg = photoMsg
                    self.ivPhoto.sd_setImage(with: url, placeholderImage: nil, options: [], progress: { [weak self] (receivedSize, expectedSize, targetUrl) in
                        guard let self = self else { return }
                        if self.message?.localIdentifier != weakMsg?.localIdentifier { return }
                        let progress = CGFloat(receivedSize) / CGFloat(expectedSize)

                        DispatchQueue.main.async {
                            self.bubbleView.progressView.setProgress(progress, animated: true)
                        }
                    }) { [weak self] (image, error, cacheType, imageUrl) in
                        guard let self = self else { return }
                        if self.message?.localIdentifier != weakMsg?.localIdentifier { return }
                        self.bubbleView.progressView.isHidden = true
                    }
                }
            }
            
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
    
    @objc private func handleImageTapped(sender: UITapGestureRecognizer) {
        if let image = ivPhoto.image {
            self.delegate?.didTapImage(cell: self, image: image)
        }
    }
}

// MARK: - StringeeProgress Delegate

extension STEPhotoCollectionViewCell: StringeeProgressDelegate {
    func progressDidChange(_ progress: StringeeProgress!) {
        print("progressDidChange")
        if progress.delegate == nil || (progress.delegate as? STEPhotoCollectionViewCell) != self {
            return
        }
        
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
        }
    }
    
    func transferCompleted(_ progress: StringeeProgress!) {
        print("transferCompleted")
        if progress.delegate == nil || (progress.delegate as? STEPhotoCollectionViewCell) != self {
            return
        }
        progress.delegate = nil
        
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(1, animated: true)
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

class STEPhotoIncomingMessageCollectionViewCell: STEPhotoCollectionViewCell {
    
    static let identifier = "STEPhotoIncomingMessageCollectionViewCell"
    
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
//        bubbleView.backgroundColor = STEColor.incomingBackground
//        bubbleView.backgroundColor = .clear
        ivPhoto.backgroundColor = STEColor.incomingBackground
        
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

class STEPhotoOutgoingMessageCollectionViewCell: STEPhotoCollectionViewCell {
    
    static let identifier = "STEPhotoOutgoingMessageCollectionViewCell"
    
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
//        bubbleView.backgroundColor = .clear
        
        maskBubbleView = UIImageView(image: STEOutgoingImage)
        ivPhoto.mask = maskBubbleView
    }
    
//    override func present(message: StringeeMessage, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
//        super.present(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
    
//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//
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
