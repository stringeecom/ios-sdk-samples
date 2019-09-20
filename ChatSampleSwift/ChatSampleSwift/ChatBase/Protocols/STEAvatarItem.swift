//
//  STEAvatarItem.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/21/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

protocol STEAvatarItem: AnyObject {
    // Trả về imageUrl để hiện thị
    var avatarImageUrl: URL? { get }
    
    // Trả về giá trị text, đại điện thông tin user để sinh image khi không có url
    var avatarInitials: String? { get }
}
