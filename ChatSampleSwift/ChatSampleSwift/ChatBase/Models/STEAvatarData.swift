//
//  STEAvatarData.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 3/27/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

class STEAvatarData: STEAvatarItem {
    var avatarImageUrl: URL?
    var avatarInitials: String?
    
    init(avatarImageUrl: URL?, avatarInitials: String?) {
        self.avatarImageUrl = avatarImageUrl
        self.avatarInitials = avatarInitials
    }
}
