//
//  STEMessagePresenting.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

protocol STEMessagePresenting {
    func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool)
    
    func shouldDisplayAvatar(should: Bool)
    
    func shouldDisplaySender(should: Bool)

    func shouldDisplayMsgStatus(should: Bool)
}
