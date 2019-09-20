//
//  SampleAvatarItem.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/24/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

class SampleAvatarItem: STEAvatarItem {
    var avatarImageUrl: URL?
    var avatarInitials: String?
    
    init(avatarImageUrl: URL? , avatarInitials: String?) {
        self.avatarInitials = avatarInitials
        self.avatarImageUrl = avatarImageUrl
    }
}
