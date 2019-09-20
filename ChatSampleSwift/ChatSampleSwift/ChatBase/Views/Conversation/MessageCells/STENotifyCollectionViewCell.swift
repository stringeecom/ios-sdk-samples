//
//  STENotifyCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/5/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STENotifyCellBubbleBackgroundColor = STEColor.darkGray
let STENotifyCellLabelNotifyColor = UIColor.white
let STENotifyCellLabelNotifyFont = UIFont.boldSystemFont(ofSize: 13)
let STENotifyCellMaxTextWidth = UIScreen.main.bounds.size.width - 60
let STENotifyCellBubbleViewheight: CGFloat = 25

class STENotifyCollectionViewCell: STEBaseCollectionViewCell {
    
    static let identifier = "STENotifyCollectionViewCell"
    
    let lbMessage: UILabel = {
        let label = UILabel()
        label.textColor = STENotifyCellLabelNotifyColor
        label.font = STENotifyCellLabelNotifyFont
        label.text = "This is a notification."
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        label.lineBreakMode = .byClipping
        label.textAlignment = .center
        return label
    }()
    
    let backview: UIView = {
        let view = UIView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private func commonInit() {
        bubbleView.backgroundColor = .clear
//        bubbleView.layer.cornerRadius = 8

        backview.backgroundColor = STENotifyCellBubbleBackgroundColor
        backview.layer.cornerRadius = 8

        bubbleView.addSubview(backview)
        backview.addSubview(lbMessage)
        
        // Layout
        configureCellForMode(mode: .notify)
        
        backview.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView).inset(UIEdgeInsets(top: STEMessageBubbleViewVerticalPadding , left: 0, bottom: STEMessageBubbleViewVerticalPadding, right: 0))
        }
        
        lbMessage.snp.makeConstraints { (make) in
            make.edges.equalTo(backview).inset(UIEdgeInsets(top: STEMessageBubbleViewVerticalPadding / 2, left: STEMessageBubbleViewHorizontalPadding / 2, bottom: STEMessageBubbleViewVerticalPadding / 2, right: STEMessageBubbleViewHorizontalPadding / 2))
        }
    }
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
        
        updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplayAvatar, shouldDisplayMsgStatus: shouldDisplayAvatar).width)
        
//        var content: String!
//        if message.type == .createGroup {
//            content = "Cuộc trò chuyện đã được tạo."
//        } else if message.type == .renameGroup {
//            content = "Thông tin cuộc trò chuyện đã được thay đổi."
//        } else {
//            content = message.content ?? STEMessageNoContentString
//        }
        
        self.lbMessage.text = STEBaseCollectionViewCell.textForNotificationMsg(message: message)
    }
    
}
