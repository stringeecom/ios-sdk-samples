//
//  STEFileCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEFileCellLabelNameFont = UIFont.boldSystemFont(ofSize: 16)
let STEFileCellLabelInfoFont = UIFont.systemFont(ofSize: 12)

let STEFileCellImageWidth: CGFloat = 40

class STEFileCollectionViewCell: STEBaseCollectionViewCell {
    
    let ivBubble: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    let ivFile: STEAvatarView = {
        let view = STEAvatarView()
        return view
    }()
    
    let lbName: UILabel = {
        let label = UILabel()
        label.text = "fileName.txt"
        label.font = STEFileCellLabelNameFont
        label.textColor = .blue
        return label
    }()
    
    let lbInfo: UILabel = {
        let label = UILabel()
        label.text = "500 KB"
        label.font = STEFileCellLabelInfoFont
        label.textColor = .orange
        return label
    }()
    
    let tapButton: UIButton = {
        let button = UIButton()
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
        
        bubbleView.addSubview(ivBubble)
        bubbleView.addSubview(ivFile)
        bubbleView.addSubview(lbName)
        bubbleView.addSubview(lbInfo)
        bubbleView.addSubview(statusView)
        bubbleView.addSubview(tapButton)
        bubbleView.progressView.delegate = self
        statusView.backgroundColor = .clear
        
        tapButton.addTarget(self, action: #selector(STEFileCollectionViewCell.handleFileTapped), for: .touchUpInside)
        
        // Layout
        ivBubble.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        
        ivFile.snp.makeConstraints { (make) in
            make.top.equalTo(bubbleView.snp.top).offset(STEMessageBubbleViewVerticalPadding * 2)
            make.left.equalTo(bubbleView.snp.left).offset(STEMessageBubbleViewHorizontalPadding)
            make.width.equalTo(ivFile.snp.height)
            make.width.equalTo(STEFileCellImageWidth)
        }
        
        lbName.snp.makeConstraints { (make) in
            make.centerY.equalTo(ivFile.snp.centerY).offset(-STEMessageBubbleViewVerticalPadding)
            make.left.equalTo(ivFile.snp.right).offset(STEMessageBubbleViewHorizontalPadding)
            make.right.equalTo(bubbleView).offset(-STEMessageBubbleViewHorizontalPadding)
        }
        
        lbInfo.snp.makeConstraints { (make) in
            make.top.equalTo(lbName.snp.bottom)
            make.left.equalTo(lbName)
        }
        
        statusView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
        
        tapButton.snp.makeConstraints { (make) in
            make.top.equalTo(ivFile)
            make.bottom.equalTo(ivFile)
            make.left.equalTo(self)
            make.right.equalTo(lbName)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.bubbleView.progressView.isHidden = true
    }
    
    // MARK: - Overide Message Presenting
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        
        self.updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).width)
        self.shouldDisplayAvatar(should: shouldDisplayAvatar)
        self.shouldDisplayMsgStatus(should: shouldDisplayMsgStatus)
        self.shouldDisplaySender(should: shouldDisplaySender)
        
        STEBaseCollectionViewCell.messageProcessingQueue.async {
            if let fileMsg = self.message as? StringeeFileMessage {
                // avatar
                let name = fileMsg.filename.count > 0 ? fileMsg.filename : STEMessageNoNameString
                let avatarItem = STEAvatarData(avatarImageUrl: nil, avatarInitials: name)
                
                let fileSize = "\(CGFloat(fileMsg.length / (1024 * 1024))) MB"
                
                // Check xem có nên show button download
                let shouldShowDownload = fileMsg.transferStatus == .readyForDownload

                DispatchQueue.main.async {
                    // Trường hợp đang transfer file (up/down) => update progress
                    fileMsg.progress?.delegate = self
                    if fileMsg.filePath != nil && (fileMsg.transferStatus == .awaitingUpload || fileMsg.transferStatus == .downloading || fileMsg.transferStatus == .uploading) {
                        self.bubbleView.progressView.setProgress(CGFloat(fileMsg.progress.fractionCompleted), animated: true)
                    }
                    
                    self.ivFile.present(avatarItem: avatarItem)
                    self.lbName.text = name
                    self.lbInfo.text = fileSize
                    
                    self.bubbleView.progressView.downloadButton.isHidden = !shouldShowDownload
                    self.bubbleView.progressView.isHidden = !(shouldShowDownload == true)
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
    @objc private func handleFileTapped() {
        print("handleFileTapped")
        if let fileMsg = self.message as? StringeeFileMessage, let filePath = fileMsg.filePath {
            let url = URL(fileURLWithPath: filePath)
            print("======= Extension \(url.pathExtension)")
            let name = (fileMsg.filename.count > 0 ? fileMsg.filename : STEMessageNoNameString) ?? STEMessageNoNameString
            self.delegate?.didTapFile(cell: self, fileUrl: url, name: name)
        }
    }
    
}

// MARK: - STEProgressViewDelegate

extension STEFileCollectionViewCell: STEProgressViewDelegate {
    func didTapDownloadButton(view: STEProgressView) {
        print("didTapDownloadButton")
        self.bubbleView.progressView.downloadButton.isHidden = true
        self.message?.downloadContent()
    }
}

// MARK: - StringeeProgress Delegate

extension STEFileCollectionViewCell: StringeeProgressDelegate {
    func progressDidChange(_ progress: StringeeProgress!) {
        print("progressDidChange")
        if progress.delegate == nil || (progress.delegate as? STEFileCollectionViewCell) != self {
            return
        }
        
        DispatchQueue.main.async {
            self.bubbleView.progressView.setProgress(CGFloat(progress.fractionCompleted), animated: true)
        }
    }
    
    func transferCompleted(_ progress: StringeeProgress!) {
        print("transferCompleted")
        if progress.delegate == nil || (progress.delegate as? STEFileCollectionViewCell) != self {
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


class STEFileIncomingMessageCollectionViewCell: STEFileCollectionViewCell {
    
    static let identifier = "STEFileIncomingMessageCollectionViewCell"
    
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
        lbName.textColor = STEColor.incomingTheme
        lbInfo.textColor = STEColor.gray
        statusView.lbTime.textColor = STEColor.gray
        
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
//
//        }
//
        
    }
}

class STEFileOutgoingMessageCollectionViewCell: STEFileCollectionViewCell {
    
    static let identifier = "STEFileOutgoingMessageCollectionViewCell"
    
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
//        bubbleView.backgroundColor = STEColor.outgoingBackground
        lbName.textColor = STEColor.outgoingTheme
        lbInfo.textColor = STEColor.outgoingTheme
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


