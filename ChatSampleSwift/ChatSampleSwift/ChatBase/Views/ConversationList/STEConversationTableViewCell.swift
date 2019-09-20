//
//  STEConversationTableViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/21/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class STEConversationTableViewCell: UITableViewCell {
    
    static let identifier = "STEConversationCellIdentifier"

    let avatarView: STEAvatarView = {
        let avatarView = STEAvatarView()
        return avatarView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        label.textColor = UIColor.black
//        label.textColor = VNColor.primary
        label.text = "Title"
        return label
    }()
    
    let lastMsgLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.gray
        label.text = "Last message"
        label.numberOfLines = 2
        return label
    }()
    
    let dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.gray
        label.text = "12/18/18"
        return label
    }()
    
    let unreadView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9
        view.clipsToBounds = true
        view.backgroundColor = UIColor.red
        return view
    }()
    
    let unreadLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.text = "5"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super .init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.lastMsgLabel)
        self.contentView.addSubview(self.dateTimeLabel)
        self.contentView.addSubview(self.unreadView)
        self.unreadView.addSubview(self.unreadLabel)
        
        // Layout
        self.avatarView.snp.makeConstraints { (make) in
            make.width.equalTo(self.contentView.snp.height).multipliedBy(0.6)
            make.width.equalTo(self.avatarView.snp.height).multipliedBy(1)
            make.left.equalTo(self.contentView.snp.left).offset(10)
            make.centerY.equalTo(self.contentView.snp.centerY)
        }
        
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.top.equalTo(self.contentView.snp.top).offset(8)
            make.right.equalTo(self.dateTimeLabel.snp.left).offset(-10).priority(.medium)
        }
        
        self.lastMsgLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(self.titleLabel.snp.leading)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(3)
            make.right.equalTo(self.contentView.snp.right).offset(-40)
        }
        
        self.dateTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.top)
            make.right.equalTo(self.contentView.snp.right).offset(-10)
        }
        
        self.unreadView.snp.makeConstraints { (make) in
            make.trailing.equalTo(self.dateTimeLabel.snp.trailing)
            make.top.equalTo(self.dateTimeLabel.snp.bottom).offset(15)
        }
        
        self.unreadLabel.snp.makeConstraints { (make) in
            make.edges.equalTo(self.unreadView).inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
        self.lastMsgLabel.text = nil
        self.unreadView.isHidden = true
        self.dateTimeLabel.text = nil
        self.avatarView.reset()
    }

}

extension STEConversationTableViewCell: STEConversationPresenting {
    func presentConversation(conversation: StringeeConversation) {
        let convName = STETitleFor(conversation: conversation)
        self.titleLabel.text = convName
        self.dateTimeLabel.text = self.dateLabelForLastUpdate(conversation: conversation)
        self.lastMsgLabel.text = self.displayTextForLastMessage(conversation: conversation)
        let sampleAvatarItem = SampleAvatarItem(avatarImageUrl: nil, avatarInitials: convName)
        self.avatarView.present(avatarItem: sampleAvatarItem)
        self.unreadView.isHidden = conversation.unread == 0
        self.unreadLabel.text = String(conversation.unread)
    }
    
}

// MARK: - Utils

extension STEConversationTableViewCell {
    
    typealias Class = STEConversationTableViewCell
    
    static var relativeDateFormatter: DateFormatter = {
        print("relativeDateFormatter")
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.dateStyle = .short
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter
    }()
    
    static var shortTimeFormatter: DateFormatter = {
        print("shortTimeFormatter")
        let shortTimeFormatter = DateFormatter()
        shortTimeFormatter.timeStyle = .short
        return shortTimeFormatter
    }()
    
    static func isDateInToday(date: Date) -> Bool {
        let unitFlags = Set<Calendar.Component>([.era, .year, .month, .day])
        let dateComponents = NSCalendar.current.dateComponents(unitFlags, from: date)
        let todayComponents = NSCalendar.current.dateComponents(unitFlags, from: Date())
        return (dateComponents.day == todayComponents.day &&
            dateComponents.month == todayComponents.month &&
            dateComponents.year == todayComponents.year &&
            dateComponents.era == todayComponents.era)
    }
    
    func dateLabelForLastUpdate(conversation: StringeeConversation?) -> String {
        guard let conversation = conversation else {
            return ""
        }
        
        if conversation.lastUpdate == 0 {
            return ""
        }
        
        let lastUpdateDate = Date(timeIntervalSince1970: Double(conversation.lastUpdate) / 1000.0)
        if Class.isDateInToday(date: lastUpdateDate) {
            return Class.shortTimeFormatter.string(from: lastUpdateDate)
        } else {
            return Class.relativeDateFormatter.string(from: lastUpdateDate)
        }
    }
    
    func displayTextForLastMessage(conversation: StringeeConversation) -> String {
        return STEDisplayTextForLastMessage(conversation: conversation)
    }
}

