//
//  STEStickerCollectionViewCell.swift
//  IVND
//
//  Created by HoangDuoc on 5/17/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEStickerMessageCollectionViewCell: STEBaseCollectionViewCell {
    
    let ivSticker: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .lightGray
        return iv
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
        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
        bubbleView.clipsToBounds = true
        
        bubbleView.addSubview(ivSticker)
        bubbleView.addSubview(statusView)
        
        
        ivSticker.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView).inset(UIEdgeInsets(top: 11, left: 1, bottom: 1, right: 1))
        }
        ivSticker.sd_imageTransition = .fade
        
        statusView.snp.makeConstraints { (make) in
            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
        
        statusView.lbTime.textColor = .white
        ivSticker.backgroundColor = .clear
        bubbleView.backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    // MARK: - Overide Message Presenting
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        
        // Layout
        updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).width)
        self.shouldDisplayAvatar(should: shouldDisplayAvatar)
        self.shouldDisplayMsgStatus(should: shouldDisplayMsgStatus)
        self.shouldDisplaySender(should: shouldDisplaySender)
        
        // Info
        statusView.update(status: message.status, timeStamp: message.created, tintColor: .white)
        if let sticker = self.message as? StringeeStickerMessage {
            
            weak var weakMsg = sticker
            
            STEBaseCollectionViewCell.messageProcessingQueue.async { [weak self] in
                // Lấy về đường dẫn local
                let strRemotePath = STEStickerBaseUrl + sticker.name
                let remoteUrl = URL(string: strRemotePath)
                let localPath = URL(string: STEStickerManager.shared.stickerDirectory)?.appendingPathComponent(sticker.category).appendingPathComponent(sticker.name).path ?? ""
                
//                print("remoteUrl \(remoteUrl)")
//                print("localPath \(localPath)")

                // Check tử cache
                if let image: UIImage = STEBaseCollectionViewCell.sharedImageCache.object(forKey: localPath as AnyObject) as? UIImage {
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if self.message?.localIdentifier != weakMsg?.localIdentifier { return }
                        
//                        print("========= Lấy được sticker từ cache")
                        self.ivSticker.image = image
                    }
                    return
                } else if let image = UIImage(contentsOfFile: localPath) {
                    // Lấy từ local
                    STEBaseCollectionViewCell.sharedImageCache.setObject(image, forKey: localPath as AnyObject)
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if self.message?.localIdentifier != weakMsg?.localIdentifier { return }
                        
//                        print("========= Lấy được sticker từ Local")
                        self.ivSticker.image = image
                    }
                } else {
                    // Lấy file từ remote URL
                    guard let self = self else { return }
                    if self.message?.localIdentifier != weakMsg?.localIdentifier { return }
                    
//                    print("========= Lấy sticker từ remote")
                    self.ivSticker.sd_setImage(with: remoteUrl, placeholderImage: nil, completed: { [weak self] (image, error, type, url) in
                        guard let self = self else {
                            return
                        }
                        
                        if error != nil {
                           self.ivSticker.image = UIImage(named: "StickersPlaceholderIcon")
                        }
                    })
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
}

class STEStickerIncomingMessageCollectionViewCell: STEStickerMessageCollectionViewCell {
    
    static let identifier = "STEStickerIncomingMessageCollectionViewCell"
    
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
    }
}

class STEStickerOutgoingMessageCollectionViewCell: STEStickerMessageCollectionViewCell {
    
    static let identifier = "STEStickerOutgoingMessageCollectionViewCell"
    
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
    }
    
}
