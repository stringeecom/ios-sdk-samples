//
//  STEColor.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/21/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

struct STEConstant {
    static let noName = "Không tên"
    static let converastionDefaultTitle = "Cuộc trò chuyện"
}

struct STEColor {
    static let lightGray = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
    static let darkGray = UIColor.darkGray.withAlphaComponent(0.8)
    static let green = UIColor(red: 63, green: 195, blue: 59, alpha: 1)
    static let gray = UIColor(red: 200, green: 200, blue: 200, alpha: 1)
    static let blue = UIColor(red: 3, green: 126, blue: 229)
    static let blueOS = UIColor(red: 0, green: 122, blue: 1)
    static let iconGrayTheme = UIColor(red: 143, green: 150, blue: 160, alpha: 1)

    static let outgoingTheme = green
    static let outgoingBackground = UIColor(hexFromString: "#E1FFC7")
//
//    static let incomingTheme = UIColor.blue
    static let incomingBackground = UIColor.white
    
//    static let outgoingTheme = UIColor(red: 247, green: 148, blue: 28)
//    static let outgoingBackground = UIColor(red: 255, green: 242, blue: 203)
    static let outgoingBorder = outgoingTheme.withAlphaComponent(0.7)

    static let incomingTheme = UIColor.blue
//    static let incomingBackground = UIColor(red: 220, green: 220, blue: 220)
    static let incomingTime = UIColor.darkGray
    static let incomingBorder = UIColor.lightGray.withAlphaComponent(0.7)
}

extension Notification.Name {
    static let STEMessageInputToolbarDidChangeHeightNotification = Notification.Name("STEMessageInputToolbarDidChangeHeightNotification")
    static let STELocalContactLoadedNotification = Notification.Name("STELocalContactLoadedNotification")

    static let STEDidTapSendContactNotification = Notification.Name("STEDidTapSendContactNotification")
    static let STEDidTapAddContactNotification = Notification.Name("STEDidTapAddContactNotification")
    
    static let STEDidTapSendMediaSourceNotification = Notification.Name("STEDidTapSendMediaSourceNotification")
    static let STEDidTapSendLocationNotification = Notification.Name("STEDidTapSendLocationNotification")
    static let STEDidTapStickerNotification = Notification.Name("STEDidTapStickerNotification")
    static let STEDidTapSendStickerNotification = Notification.Name("STEDidTapSendStickerNotification")

    // Audio
    static let STEPlayerManagerTrackingNotification = Notification.Name("STEPlayerManagerTrackingNotification")
    static let STEPlayerManagerEndItemNotification = Notification.Name("STEPlayerManagerEndItemNotification")

    // Sticker
    static let STEStickerManagerDidEditStickerNotification = Notification.Name("STEStickerManagerDidEditStickerNotification")

    static let STEUnreadMessageChangeNotification = Notification.Name("STEUnreadMessageChangeNotification")
}


