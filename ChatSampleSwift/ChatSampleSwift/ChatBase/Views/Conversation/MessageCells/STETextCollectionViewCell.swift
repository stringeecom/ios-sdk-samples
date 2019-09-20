//
//  STETextMessageCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import SnapKit

//let STETextMessageContentInset: CGFloat = 8.0

let STETextCellLabelNameFont = UIFont.boldSystemFont(ofSize: 16)
let STETextCellLabelTextFont = UIFont.systemFont(ofSize: 16)
let STETextCellLabelTextColor = UIColor.black

class STETextCollectionViewCell: STEBaseCollectionViewCell {
    
    // MARK: - Init
    
    let ivBubble: UIImageView = {
        let iv = UIImageView()
        return iv
    }()

    let lbName: UILabel = {
        let label = UILabel()
        label.text = "User Name"
        label.font = STETextCellLabelNameFont
        label.textColor = .red
        return label
    }()
    
    let lbText: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = STETextCellLabelTextFont
        label.textColor = STETextCellLabelTextColor
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        // Để chế độ này thì việc tính size của String với core text mới chính xác
        label.lineBreakMode = .byClipping
        return label
    }()
    
    var labelTapGesture: UITapGestureRecognizer!
    var tappedURL: URL?
    var tappedPhone: String?
    
    var displaySenderContraint: Constraint? = nil
    var noDisplaySenderContraint: Constraint? = nil
    
    var senderHeightContraint: Constraint? = nil
    var senderBottomMarginContraint: Constraint? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.backgroundColor = .clear
        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
        
        bubbleView.addSubview(ivBubble)
        bubbleView.addSubview(lbName)
        bubbleView.addSubview(lbText)
        bubbleView.addSubview(statusView)
        statusView.backgroundColor = .clear
        
        // Layout
        ivBubble.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        
        lbName.snp.makeConstraints { (make) in
            make.top.equalTo(STEMessageBubbleViewVerticalPadding)
            make.left.equalTo(STEMessageBubbleViewHorizontalPadding)
            senderHeightContraint = make.height.equalTo(STEMessageBubbleViewLabelNameHeight).constraint
        }
        
        lbText.snp.makeConstraints { (make) in
            senderBottomMarginContraint = make.top.equalTo(lbName.snp.bottom).offset(STEMessageBubbleViewLabelNameBottomMargin).constraint
            make.left.equalTo(STEMessageBubbleViewHorizontalPadding)
            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.bottom.equalTo(statusView.snp.top).offset(0)
        }

        statusView.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.bottom.equalTo(0)
//            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
//            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
        
        labelTapGesture = UITapGestureRecognizer(target: self, action: #selector(STETextCollectionViewCell.handleTextLabelTapped(gesture:)))
        labelTapGesture.delegate = self
        lbText.isUserInteractionEnabled = true
        lbText.addGestureRecognizer(labelTapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //        print("===== Name \(lbName.frame)")
        //        print("===== Status \(statusView.frame)")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lbText.attributedText = nil
        tappedURL = nil
        tappedPhone = nil
    }
    
    // MARK: - Overide Message Presenting
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        
        updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).width)
        self.shouldDisplayAvatar(should: shouldDisplayAvatar)
        self.shouldDisplayMsgStatus(should: shouldDisplayMsgStatus)
        self.shouldDisplaySender(should: shouldDisplaySender)
        
//        let attributes = [NSAttributedString.Key.font: STETextCellLabelTextFont, NSAttributedString.Key.foregroundColor: STETextCellLabelTextColor]
//        let content = message.content ?? STEMessageNoContentString
//        let attributeString = NSAttributedString(string: content, attributes: attributes)
        
//        self.lbText.text = content
        
        if shouldDisplaySender {
            var name: String?
            if let part = STEBaseCollectionViewCell.partFor(message: message, conv: conv) {
                name = part.displayName?.count ?? 0 > 0 ? part.displayName : part.userId
            }
            name = name?.count ?? 0 > 0 ? name : STEMessageNoNameString
            
            self.lbName.text = name
        }
        
    }
    
    override func shouldDisplayAvatar(should: Bool) {
        displayAvatar(should)
    }
    
    override func shouldDisplaySender(should: Bool) {
        if (should) {
            senderHeightContraint?.update(offset: STEMessageBubbleViewLabelNameHeight)
            senderBottomMarginContraint?.update(offset: STEMessageBubbleViewLabelNameBottomMargin)
//            displaySenderContraint?.activate()
//            noDisplaySenderContraint?.deactivate()
        } else {
            senderHeightContraint?.update(offset: 0)
            senderBottomMarginContraint?.update(offset: 0)
//            displaySenderContraint?.deactivate()
//            noDisplaySenderContraint?.activate()
        }
        self.lbName.isHidden = !should
    }
    
    override func shouldDisplayMsgStatus(should: Bool) {
        statusView.displayMsgStatus(should)
    }
    
    func attributedString(forText: String, attributes: [NSAttributedString.Key : Any]?, contentDetectedAttributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: forText, attributes: attributes)
        if let results = STETextCheckingResults(text: forText, checkingTypes: [.link, .phoneNumber]) {
            for result in results {
                attributedString.addAttributes(contentDetectedAttributes, range: result.range)
            }
        }
        return attributedString
    }
    
    @objc private func handleTextLabelTapped(gesture: UITapGestureRecognizer) {
        if let tappedPhone = self.tappedPhone {
            self.delegate?.didTapLinkOrPhone(cell: self, content: tappedPhone, isLink: false)
        } else if let tappedURL = self.tappedURL {
            self.delegate?.didTapLinkOrPhone(cell: self, content: tappedURL, isLink: true)
        }
        self.tappedPhone = nil
        self.tappedURL = nil
    }
}

extension STETextCollectionViewCell {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("gestureRecognizerShouldBegin")
        if gestureRecognizer != self.labelTapGesture { return true}
        
        print("========= Thực hiện detect")
        let textLabel = self.lbText
        let tapLocation = gestureRecognizer.location(in: textLabel)
        
        guard let attributeText = textLabel.attributedText else { return true}
        
        // init storage
        let textStorage = NSTextStorage.init(attributedString: attributeText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        // init text container
        let textContainer = NSTextContainer(size: textLabel.frame.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = textLabel.numberOfLines
        textContainer.lineBreakMode = textLabel.lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let characterIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if let results = STETextCheckingResults(text: textLabel.attributedText?.string ?? "", checkingTypes: [.link, .phoneNumber]) {
            for result in results {
                if NSLocationInRange(characterIndex, result.range) {
                    if result.resultType == .link {
                        tappedURL = result.url
                        return true
                    } else if result.resultType == .phoneNumber {
                        tappedPhone = result.phoneNumber
                        return true
                    }
                    tappedURL = result.url
                    return true
                }
            }
        }
        
        return false
    }
}

class STETextIncomingMessageCollectionViewCell: STETextCollectionViewCell {
    
    static let identifier = "STETextIncomingMessageCollectionViewCell"

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
        statusView.lbTime.textColor = STEColor.incomingTime
        
        
        self.ivBubble.image = STEIncomingImage
        self.ivBubble.tintColor = STEColor.incomingBackground
    }
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        statusView.update(status: message.status, timeStamp: message.created, tintColor: STEColor.incomingTime)
        
        STEBaseCollectionViewCell.messageProcessingQueue.async {
            let highlightAttributes = [NSAttributedString.Key.foregroundColor: STEColor.incomingTheme] as [NSAttributedString.Key : Any]
            let content = message.content ?? STEMessageNoContentString
            let attributedText = self.attributedString(forText: content, attributes: nil, contentDetectedAttributes: highlightAttributes)
            
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.incomingBackground, borderColor: STEColor.incomingBorder, isOutgoing: false)
            
            DispatchQueue.main.async {
                self.lbText.attributedText = attributedText
                
//                for layer in self.bubbleView.layer.sublayers! {
//                    if layer.isKind(of: CAShapeLayer.self) {
//                        layer.removeFromSuperlayer()
//                        break
//                    }
//                }
//                self.bubbleView.layer.insertSublayer(bubbleLayer, at: 0)
                

            }
            
        }
        
        
    }
}

class STETextOutgoingMessageCollectionViewCell: STETextCollectionViewCell {
    
    static let identifier = "STETextOutgoingMessageCollectionViewCell"
    
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
//        bubbleView.backgroundColor = .clear
        statusView.lbTime.textColor = STEColor.outgoingTheme
//        statusView.ivStatus.tintColor = STEColor.green
        
        self.ivBubble.image = STEOutgoingImage
        self.ivBubble.tintColor = STEColor.outgoingBackground
    }
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        statusView.update(status: message.status, timeStamp: message.created, tintColor: STEColor.outgoingTheme)
        
        STEBaseCollectionViewCell.messageProcessingQueue.async {
            let highlightAttributes = [NSAttributedString.Key.foregroundColor: STEColor.outgoingTheme] as [NSAttributedString.Key : Any]
            let content = message.content ?? STEMessageNoContentString
            let attributedText = self.attributedString(forText: content, attributes: nil, contentDetectedAttributes: highlightAttributes)
            
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.outgoingBackground, borderColor: STEColor.outgoingBorder, isOutgoing: true)
            
            
            DispatchQueue.main.async {
                self.lbText.attributedText = attributedText
                
//                for layer in self.bubbleView.layer.sublayers! {
//                    if layer.isKind(of: CAShapeLayer.self) {
//                        layer.removeFromSuperlayer()
//                        break
//                    }
//                }
//                self.bubbleView.layer.insertSublayer(bubbleLayer, at: 0)
                
            }
        }
    }
}
