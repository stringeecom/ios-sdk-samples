//
//  STEBaseCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import SnapKit
import CoreLocation

enum STECellType {
    case text
    case photo
    case video
    case audio
    case contact
    case file
    case notify
}

enum STECellMode {
    case incoming
    case outgoing
    case notify
}

let STEMessageCellAvatarImageLead: CGFloat = 3.0
let STEMessageCellAvatarImageWidth: CGFloat = 40.0
let STECreateGroupNotificationContent = "Cuộc trò chuyện đã được tạo."
let STERenameGroupNotificationContent = "Thông tin cuộc trò chuyện đã được thay đổi."

protocol STEMessageCellDelegate: AnyObject {
    func didTapContactDetailButton(cell: STEBaseCollectionViewCell, contact: STEVCard)
    func didTapFile(cell: STEBaseCollectionViewCell, fileUrl: URL, name: String)
    func didTapImage(cell: STEBaseCollectionViewCell, image: UIImage)
    func didTapPlayVideo(cell: STEBaseCollectionViewCell, url: URL)
    func didTapLocation(cell: STEBaseCollectionViewCell, location: CLLocationCoordinate2D)
    func didBeginLongGesture(message: StringeeMessage)
    func didTapLinkOrPhone(cell: STEBaseCollectionViewCell, content: Any, isLink: Bool)
}


class STEBaseCollectionViewCell: UICollectionViewCell, STEMessagePresenting {
    
    static let messageProcessingQueue = DispatchQueue(label: "com.stringee.messageprocessingqueue", attributes: .concurrent)
    static let sharedImageCache = NSCache<AnyObject, AnyObject>()
    static let sharedSizeCache = NSCache<AnyObject, AnyObject>()
    static let sharedMsgContent = NSCache<AnyObject, AnyObject>()
    
    var message: StringeeMessage?
    
    var shoudDisplayAvatar = true
    var shouldDisplaySender = true
    var shouldDisplayMessageStatus = true
    
    let bubbleView: STEMessageBubbleView = {
        let view = STEMessageBubbleView()
        return view
    }()
    
    let avatarView: STEAvatarView = {
        let avatarView = STEAvatarView()
        return avatarView
    }()
    
    let statusView: STEMessageStatusView = {
        let view = STEMessageStatusView()
        view.layer.cornerRadius = STEMessageStatusViewCornerRadius
        view.clipsToBounds = true
        return view
    }()
    
    var bubbleWithAvatarLeadConstraint: Constraint? = nil
    var bubbleWithoutAvatarLeadConstraint: Constraint? = nil
    
    var avatarImageWidthContraint: Constraint? = nil
    var bubleViewWidthContraint: Constraint? = nil
    
    weak var delegate: STEMessageCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.message?.progress?.delegate = nil
        self.message = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    private func baseInit() {
        contentView.addSubview(bubbleView)
        contentView.addSubview(avatarView)
        
        // Layout
        let maxBubbleWidth = STEMaxCellWidth + 2 * STEMessageBubbleViewHorizontalPadding
        bubbleView.snp.makeConstraints { (make) in
            bubleViewWidthContraint = make.width.equalTo(maxBubbleWidth).constraint
            make.top.equalTo(contentView.snp.top).offset(STEMessageBubbleViewVerticalMargin)
            make.bottom.equalTo(contentView.snp.bottom).offset(-STEMessageBubbleViewVerticalMargin)
            //            make.width.greaterThanOrEqualTo(<#T##other: ConstraintRelatableTarget##ConstraintRelatableTarget#>)
        }
        
        avatarView.snp.makeConstraints { (make) in
            make.bottom.equalTo(bubbleView)
            make.width.equalTo(avatarView.snp.height)
            avatarImageWidthContraint = make.width.equalTo(STEMessageCellAvatarImageWidth).constraint
        }
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(STEBaseCollectionViewCell.handleLongGestureTapped(gesture:)))
        longGesture.minimumPressDuration = 0.5
        longGesture.delaysTouchesBegan = true
        longGesture.delegate = self
        bubbleView.addGestureRecognizer(longGesture)
    }
    
    func configureCellForMode(mode: STECellMode) {
        
        switch mode {
        case .incoming:
            avatarView.snp.makeConstraints { (make) in
                make.left.equalTo(contentView.snp.left).offset(STEMessageCellAvatarImageLead)
            }
            bubbleView.snp.makeConstraints { (make) in
                bubbleWithAvatarLeadConstraint = make.left.equalTo(avatarView.snp.right).offset(STEMessageBubbleViewHorizontalMargin).constraint
                bubbleWithoutAvatarLeadConstraint = make.left.equalTo(contentView.snp.left).offset(STEMessageBubbleViewHorizontalMargin).priority(.high).constraint
            }
            bubbleWithoutAvatarLeadConstraint?.deactivate()
        case .outgoing:
            avatarView.snp.makeConstraints { (make) in
                make.right.equalTo(contentView.snp.right).offset(-STEMessageCellAvatarImageLead)
                bubbleWithAvatarLeadConstraint = make.left.equalTo(bubbleView.snp.right).offset(STEMessageBubbleViewHorizontalMargin).constraint
            }
            
            bubbleView.snp.makeConstraints { (make) in
                bubbleWithoutAvatarLeadConstraint = make.right.equalTo(contentView.snp.right).offset(-STEMessageBubbleViewHorizontalMargin).priority(.high).constraint
            }
            bubbleWithoutAvatarLeadConstraint?.deactivate()
        case .notify:
            bubbleView.snp.makeConstraints { (make) in
                make.centerX.equalTo(contentView.snp.centerX)
            }
            avatarView.isHidden = true
        }
        
        displayAvatar(shoudDisplayAvatar)
    }
    
    func updateBubbleWidth(width: CGFloat) {
        bubleViewWidthContraint?.update(offset: width)
    }
    
    // MARK: - Confirm Message Presenting
    
    func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        if shouldDisplayAvatar {
            var name: String?
            var avatar: String?
            
            if let part = STEBaseCollectionViewCell.partFor(message: message, conv: conv) {
                name = part.displayName
                avatar = part.avatarUrl
            }
            
            name = name?.count ?? 0 > 0 ? name : (message.sender.count > 0 ? message.sender : STEMessageNoNameString)
            let avatarUrl: URL? = avatar?.count ?? 0 > 0 ? URL(string: avatar!) : nil

            let avatarData = STEAvatarData(avatarImageUrl: avatarUrl, avatarInitials: name)
            self.avatarView.present(avatarItem: avatarData)
        }
    }
    
    func shouldDisplayAvatar(should: Bool) {
        fatalError("func is not implemented in the base cell")
    }
    
    func shouldDisplaySender(should: Bool) {
        fatalError("func is not implemented in the base cell")
        
    }
    
    func shouldDisplayMsgStatus(should: Bool) {
        fatalError("func is not implemented in the base cell")
    }
    
    // MARK: - Actions
    @objc private func handleLongGestureTapped(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            print("=========== BEGIN")
            if let message = self.message, message.type != .notify, message.type != .createGroup, message.type != .renameGroup {
                self.delegate?.didBeginLongGesture(message: message)
            }
            break
        case .changed:
            print("=========== CHANGED")
            break
        case .ended:
            print("=========== ENDED")
            break
        default:
            break
        }
    }
}

// MARK: - Gesture

extension STEBaseCollectionViewCell: UIGestureRecognizerDelegate {
    
}


// MARK: - Utils

extension STEBaseCollectionViewCell {
    func displayAvatar(_ should: Bool) {
        if should == shoudDisplayAvatar { return }
        
        if should {
            bubbleWithAvatarLeadConstraint?.activate()
            bubbleWithoutAvatarLeadConstraint?.deactivate()
            avatarImageWidthContraint?.update(offset: STEMessageCellAvatarImageWidth)
        } else {
            bubbleWithAvatarLeadConstraint?.deactivate()
            bubbleWithoutAvatarLeadConstraint?.activate()
            avatarImageWidthContraint?.update(offset: 0)
        }
        
        shoudDisplayAvatar = should
    }
    
    static func partFor(message: StringeeMessage, conv: StringeeConversation) -> StringeeIdentity? {
        guard let parts = conv.participants as? Set<StringeeIdentity>, parts.count > 0 else { return nil }
        
        for part in parts {
            if part.userId == message.sender {
                return part
            }
        }
        
        return nil
    }
    
    static func textForNotificationMsg(message: StringeeMessage) -> String {
        if message.type == .createGroup {
            return STECreateGroupNotificationContent
        }
        
        if message.type == .renameGroup {
            return STERenameGroupNotificationContent
        }
        
        
        if message.type != .notify || message.content == nil || message.content.count == 0 {
            return STEMessageNoContentString
        }
        
        guard let msgData = message.content.toDictionary(), let type = msgData["type"] as? Int else {
            return STEMessageNoContentString
        }
        
        switch type {
        case 1:
            // user được add tới group
            if let content = sharedMsgContent.object(forKey: message.identifier as AnyObject) as? String {
                return content
            }
            
            guard let participants = msgData["participants"] as? [[String: Any]], participants.count > 0, let addedInfo = msgData["addedInfo"] as? [String: Any] else {
                return STEMessageNoContentString
            }
            
            var isAddedUser = ""
            for part in participants {
                let user = part["user"] as? String ?? ""
                let name = part["displayName"] as? String ?? ""
                if isAddedUser.isEmpty {
                    isAddedUser += name.count > 0 ? name : user
                } else {
                    isAddedUser += ", " + (name.count > 0 ? name : user)
                }
            }
            
            let addUser = addedInfo["user"] as? String ?? ""
            let addUserName = addedInfo["displayName"] as? String ?? ""
            
            let returnContent = (addUserName.count > 0 ? addUserName : addUser) + " đã thêm \(isAddedUser) tới cuộc trò chuyện"
            
            if let serverId = message.identifier {
                sharedMsgContent.setObject(returnContent as AnyObject, forKey: serverId as AnyObject)
            }
            
            return returnContent

        case 2:
            // user bị xoá khỏi group
            if let content = sharedMsgContent.object(forKey: message.identifier as AnyObject) as? String {
                return content
            }
            
            guard let participants = msgData["participants"] as? [[String: Any]], participants.count > 0, let addedInfo = msgData["addedInfo"] as? [String: Any] else {
                return STEMessageNoContentString
            }
            var isRemovedUser = ""
            for part in participants {
                let user = part["user"] as? String ?? ""
                let name = part["displayName"] as? String ?? ""
                if isRemovedUser.isEmpty {
                    isRemovedUser += name.count > 0 ? name : user
                } else {
                    isRemovedUser += ", " + (name.count > 0 ? name : user)
                }
            }
            
            let removeUser = addedInfo["user"] as? String ?? ""
            let removeUserName = addedInfo["displayName"] as? String ?? ""
            
            let returnContent = (removeUserName.count > 0 ? removeUserName : removeUser) + " đã xoá \(isRemovedUser) khỏi cuộc trò chuyện"

            if let serverId = message.identifier {
                sharedMsgContent.setObject(returnContent as AnyObject, forKey: serverId as AnyObject)
            }
            
            return returnContent
        case 3:
            // group được đổi tên
            return "Cuộct trò chuyện đã được đổi tên"
        default:
            return STEMessageNoContentString
        }

    }
}

// MARK: - Cell Size Calculations

extension STEBaseCollectionViewCell {
    static func cellSizeFor(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) -> CGSize {
        if let localId = message.localIdentifier, let serverId = message.identifier, let size = sharedSizeCache.object(forKey: (localId + serverId) as AnyObject) as? CGSize {
            return size
        }
        switch message.type {
        case .createGroup:
            return cellSizeFor(notifyMsg: message)
        case .renameGroup:
            return cellSizeFor(notifyMsg: message)
        case .notify:
            return cellSizeFor(notifyMsg: message)
        case .photo:
            return cellSizeFor(photoMsg: message)
        case .location:
            return CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
        case .contact:
            return CGSize(width: STEMessageBubbleContactWidth, height: STEMessageBubbleContactHeight)
        case .video:
            return cellSizeFor(videoMsg: message)
        case .file:
            return CGSize(width: STEMessageBubbleFileWidth, height: STEMessageBubbleFileHeight)
        case .audio:
            return CGSize(width: STEMessageBubbleAudioWidth, height: STEMessageBubbleAudioHeight)
        case .sticker:
            return CGSize(width: STEMessageBubbleStickerWidth, height: STEMessageBubbleStickerHeight)
        default:
            return cellSizeFor(textMsg: message, conv: conv, shouldDisplayAvatar, shouldDisplaySender, shouldDisplayMsgStatus)
        }
    }
    
    private static func cellSizeFor(textMsg: StringeeMessage, conv: StringeeConversation, _ shouldDisplayAvatar: Bool, _ shouldDisplaySender: Bool, _ shouldDisplayMsgStatus: Bool) -> CGSize {
        // Tính size cho text
        let text = textMsg.content ?? STEMessageNoContentString
        let textAttributes = [NSAttributedString.Key.font: STETextCellLabelTextFont, NSAttributedString.Key.foregroundColor: STETextCellLabelTextColor]
        let textAttributeString = NSAttributedString(string: text, attributes: textAttributes)
        let textSize = STESizeFor(attributeString: textAttributeString)
        
        // Tính size cho lbName
//        let name = textMsg.sender ?? STEMessageNoContentString
        
        var nameSize = CGSize.zero
        if shouldDisplaySender {
            var name: String?
            if let part = partFor(message: textMsg, conv: conv) {
                name = part.displayName?.count ?? 0 > 0 ? part.displayName : part.userId
            }
            name = name?.count ?? 0 > 0 ? name : STEMessageNoNameString
            
            let nameAttributes = [NSAttributedString.Key.font: STETextCellLabelNameFont]
            let nameAttributeString = NSAttributedString(string: name!, attributes: nameAttributes)
            nameSize = STESizeFor(attributeString: nameAttributeString, height: STEMessageBubbleViewLabelNameHeight)
        }
        
        // Tính size cho lbTime
        let date = Date(timeIntervalSince1970: Double(textMsg.created / 1000))
        let time = STEUtils.shortTimeFormatter.string(from: date)
        
        let timeAttributes = [NSAttributedString.Key.font: STEMessageStatusViewLabelTimeFont]
        let timeAttributeString = NSAttributedString(string: time, attributes: timeAttributes)
        let timeSize = STESizeFor(attributeString: timeAttributeString, height: STEMessageBubbleViewStatusViewHeight)

        // Tính width cho statusView
        let statusViewWidth: CGFloat!
        if shouldDisplayMsgStatus {
            statusViewWidth = STEMessageStatusViewHorizontalPadding + timeSize.width + STEMessageStatusViewHorizontalPadding * 0.5 + STEMessageBubbleViewStatusViewHeight - 2 * STEMessageStatusViewVerticalPadding + STEMessageStatusViewHorizontalPadding
        } else {
            statusViewWidth = STEMessageStatusViewHorizontalPadding + timeSize.width + STEMessageStatusViewHorizontalPadding
        }
        
        // Tính width cho BubbleView
        var finalSize: CGSize = .zero
        let maxWidth = Swift.max(textSize.width, nameSize.width, statusViewWidth)
        
        var finalWidth = (maxWidth + STEMessageBubbleViewHorizontalPadding * 2).rounded(.up)
        if (finalWidth + timeSize.width) < STEMaxCellWidth {
            finalWidth += timeSize.width
        }
        
        finalSize.width = finalWidth
        
        // Tính height cho BubbleView
        if shouldDisplaySender {
            finalSize.height = (textSize.height + STEMessageBubbleViewStatusViewHeight + STEMessageBubbleViewLabelNameHeight + STEMessageBubbleViewVerticalPadding + STEMessageBubbleViewLabelNameBottomMargin + STEMessageBubbleViewVerticalMargin * 2).rounded(.up)
        } else {
            finalSize.height = (textSize.height + STEMessageBubbleViewStatusViewHeight + STEMessageBubbleViewVerticalPadding + STEMessageBubbleViewVerticalMargin * 2).rounded(.up)
        }
        
        // Cache lai size
        if let localId = textMsg.localIdentifier, let serverId = textMsg.identifier {
            sharedSizeCache.setObject(finalSize as AnyObject, forKey: (localId + serverId) as AnyObject)
        }
        
        return finalSize
    }
    
    private static func cellSizeFor(notifyMsg: StringeeMessage) -> CGSize {
        // Tính size cho text
        var content: String!
        if notifyMsg.type == .createGroup {
            content = STECreateGroupNotificationContent
        } else if notifyMsg.type == .renameGroup {
            content = STERenameGroupNotificationContent
        } else {
//            content = notifyMsg.content ?? STEMessageNoContentString
            content = STEBaseCollectionViewCell.textForNotificationMsg(message: notifyMsg)
        }
        
        let textAttributes = [NSAttributedString.Key.font: STENotifyCellLabelNotifyFont, NSAttributedString.Key.foregroundColor: STENotifyCellLabelNotifyColor]
        let textAttributeString = NSAttributedString(string: content, attributes: textAttributes)
        var textSize = STESizeFor(attributeString: textAttributeString, width: STENotifyCellMaxTextWidth)
        
        textSize.width += STEMessageBubbleViewHorizontalPadding
        textSize.height += STEMessageBubbleViewVerticalPadding * 3 + STEMessageBubbleViewVerticalMargin * 2 + 1
        
        // Cache lai size
        if let localId = notifyMsg.localIdentifier, let serverId = notifyMsg.identifier {
            sharedSizeCache.setObject(textSize as AnyObject, forKey: (localId + serverId) as AnyObject)
        }
        
        return textSize
    }
    
    private static func cellSizeFor(photoMsg: StringeeMessage) -> CGSize {
        if let msg = photoMsg as? StringeePhotoMessage {
            let size = STEContraintImageSizeToCellSize(ratio: CGFloat(msg.ratio))
            if __CGSizeEqualToSize(size, .zero) {
                return CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
            }
            
            // Cache lai size
            if let localId = photoMsg.localIdentifier, let serverId = photoMsg.identifier {
                sharedSizeCache.setObject(size as AnyObject, forKey: (localId + serverId) as AnyObject)
            }
            
            return size
        }
        
        return CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
    }
    
    private static func cellSizeFor(videoMsg: StringeeMessage) -> CGSize {
        if let msg = videoMsg as? StringeeVideoMessage {
            let size = STEContraintImageSizeToCellSize(ratio: CGFloat(msg.ratio))
            if __CGSizeEqualToSize(size, .zero) {
                return CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
            }
            
            // Cache lai size
            if let localId = msg.localIdentifier, let serverId = msg.identifier {
                sharedSizeCache.setObject(size as AnyObject, forKey: (localId + serverId) as AnyObject)
            }
            
            return size
        }
        
        return CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
    }
}
