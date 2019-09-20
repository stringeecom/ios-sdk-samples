//
//  STEContactCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEContactCellLabelNameFont = UIFont.systemFont(ofSize: 16)
let STEContactCellLabelInfoFont = UIFont.systemFont(ofSize: 15)

let STEContactCellButtonDetailCornerRadius: CGFloat = 5
let STEContactCellButtonDetailMainColor = UIColor.blue
let STEContactCellButtonDetailTitleFont = UIFont.boldSystemFont(ofSize: 15)

let STEContactCellAvatarViewWidth: CGFloat = 40
let STEContactCellButtonDetailHeight: CGFloat = 35

class STEContactCollectionViewCell: STEBaseCollectionViewCell {
    
    let ivBubble: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    let contactAvatarView: STEAvatarView = {
        let view = STEAvatarView()
        return view
    }()
    
    let lbName: UILabel = {
        let label = UILabel()
        label.text = "User Name"
        label.font = STEContactCellLabelNameFont
        label.textColor = STEColor.incomingTheme
        return label
    }()
    
    let lbInfo: UILabel = {
        let label = UILabel()
        label.text = "0972684925"
        label.font = STEContactCellLabelInfoFont
        return label
    }()
    
    let btDetail: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = STEContactCellButtonDetailCornerRadius
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = STEColor.incomingTheme.cgColor
        button.setTitleColor(STEColor.incomingTheme, for: .normal)
        button.titleLabel?.font = STEContactCellButtonDetailTitleFont
        button.backgroundColor = .white
        button.setTitle("VIEW CONTACT", for: .normal)
    
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
//        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
//        bubbleView.clipsToBounds = true
        
        statusView.backgroundColor = .clear
        
        bubbleView.addSubview(ivBubble)
        bubbleView.addSubview(contactAvatarView)
        bubbleView.addSubview(lbName)
        bubbleView.addSubview(lbInfo)
        bubbleView.addSubview(btDetail)
        bubbleView.addSubview(statusView)
        
        btDetail.addTarget(self, action: #selector(viewDetailTapped), for: .touchUpInside)

        // Layout
        ivBubble.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        
        contactAvatarView.snp.makeConstraints { (make) in
            make.top.equalTo(bubbleView).offset(STEMessageBubbleViewVerticalPadding)
            make.left.equalTo(bubbleView).offset(STEMessageBubbleViewHorizontalPadding)
            make.width.equalTo(contactAvatarView.snp.height)
            make.width.equalTo(STEContactCellAvatarViewWidth)
        }
        
        lbName.snp.makeConstraints { (make) in
            make.top.equalTo(contactAvatarView.snp.top)
            make.left.equalTo(contactAvatarView.snp.right).offset(STEMessageBubbleViewHorizontalPadding)
            make.right.equalTo(bubbleView.snp.right).offset(-STEMessageBubbleViewHorizontalPadding)
        }
        
        lbInfo.snp.makeConstraints { (make) in
            make.left.equalTo(lbName.snp.left)
            make.top.equalTo(lbName.snp.bottom).offset(STEMessageBubbleViewVerticalPadding / 2)
            make.right.equalTo(lbName)
        }
        
        btDetail.snp.makeConstraints { (make) in
            make.bottom.equalTo(statusView.snp.top).offset(-STEMessageBubbleViewVerticalPadding)
            make.left.equalTo(bubbleView.snp.left).offset(STEMessageBubbleViewHorizontalPadding)
            make.right.equalTo(bubbleView.snp.right).offset(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEContactCellButtonDetailHeight)
        }
        
//        statusView.snp.makeConstraints { (make) in
//            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
//            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
//            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
//        }

        statusView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
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
        if let contactMsg = self.message as? StringeeContactMessage {
            lbName.text = contactMsg.fullname.count > 0 ? contactMsg.fullname : STEConstant.noName
            
            if let infos = contactMsg.infos as? [[String: String]], let info = infos.first, let phone = info.values.first {
                lbInfo.text = phone
            }
            
            let avatarItem = STEAvatarData(avatarImageUrl: nil, avatarInitials: lbName.text)
            contactAvatarView.present(avatarItem: avatarItem)
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
    
    @objc private func viewDetailTapped() {
        if let contactMsg = self.message as? StringeeContactMessage, let contact = contactMsg.cnContact {
            let vcardContact = STEVCard(contact: contact)
            self.delegate?.didTapContactDetailButton(cell: self, contact: vcardContact)
        }
    }
}

class STEContactIncomingMessageCollectionViewCell: STEContactCollectionViewCell {
    
    static let identifier = "STEContactIncomingMessageCollectionViewCell"
    
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
        statusView.lbTime.textColor = STEColor.incomingTime
        lbName.textColor = STEColor.incomingTheme
        btDetail.setTitleColor(STEColor.incomingTheme, for: .normal)
        btDetail.layer.borderColor = STEColor.incomingTheme.cgColor
        
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

class STEContactOutgoingMessageCollectionViewCell: STEContactCollectionViewCell {
    
    static let identifier = "STEContactOutgoingMessageCollectionViewCell"
    
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
        statusView.lbTime.textColor = STEColor.outgoingTheme
        lbName.textColor = STEColor.outgoingTheme
        btDetail.setTitleColor(STEColor.outgoingTheme, for: .normal)
        btDetail.layer.borderColor = STEColor.outgoingTheme.cgColor
        
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
