//
//  IconItem.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 5/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation
import Parchment

struct IconItem: PagingItem, Hashable, Comparable {
    
    let icon: String
    let index: Int
    let image: UIImage?
    
    init(icon: String, index: Int) {
        self.icon = icon
        self.index = index
        if icon.contains(STEStickerManager.shared.stickerDirectory) {
            // Là sticker thì lấy theo filePath
            self.image = UIImage(contentsOfFile: icon)
        } else {
            // là ảnh default thì lấy theo tên
            self.image = UIImage(named: icon)
        }
        
    }
    
    var hashValue: Int {
        return icon.hashValue
    }
    
    static func <(lhs: IconItem, rhs: IconItem) -> Bool {
        return lhs.index < rhs.index
    }
    
    static func ==(lhs: IconItem, rhs: IconItem) -> Bool {
        return (
            lhs.index == rhs.index &&
                lhs.icon == rhs.icon
        )
    }
}
