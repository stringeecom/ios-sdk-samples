//
//  STEContactTableViewCell.swift
//  stringeex
//
//  Created by HoangDuoc on 12/25/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class STEContactTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarView: STEAvatarView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbPhone: UILabel!
    
    static let defaultHeight: CGFloat = 70.0
    static let identifier = "STEContactTableViewCell"
    
    var contact: STEVCard!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lbName.text = nil
        self.lbPhone.text = nil
        self.avatarView.reset()
    }
    
    func present(contact: STEVCard) {
        self.contact = contact
        self.lbName.text = contact.name
        self.lbPhone.text = contact.infos.first?.values.first as? String
        
        var avatarInitials = contact.name.count > 0 ? contact.name : lbPhone.text
        avatarInitials = avatarInitials?.count ?? 0 > 0 ? avatarInitials : STEMessageNoNameString
        let avatarItem = STEAvatarData(avatarImageUrl: nil, avatarInitials: avatarInitials)
        self.avatarView.present(avatarItem: avatarItem)
    }
    

}
