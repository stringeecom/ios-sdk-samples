//
//  Stringeeimplement.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

let USER_ID_KEY = "USER_ID_KEY"

let user1 = ""
let user2 = ""

class StringeeImplement: NSObject {
    
    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()

    var userId: String!

    private override init() {
        super.init()
        // Lấy về userId cho thằng hiện tại
        if let savedUserId = UserDefaults.standard.object(forKey: USER_ID_KEY) as? String, savedUserId.count > 0 {
            userId = savedUserId
        } else if let currentUserId = stringeeClient.userId, currentUserId.count > 0 {
            userId = currentUserId
        } else {
            userId = ""
        }
        
        stringeeClient.connectionDelegate = self;
    }
    
    func connectToStringeeServer() {
        stringeeClient.connect(withAccessToken: user1)
    }
}

extension StringeeImplement: StringeeConnectionDelegate {
    
    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect \(stringeeClient.userId!)")
        AppStateManager.shared.convList?.title = stringeeClient.userId
        
        // Lưu lại userId
        if let userId = stringeeClient.userId, userId.count > 0 {
            self.userId = userId
            UserDefaults.standard.set(userId, forKey: USER_ID_KEY)
        }
    }
    
    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect \(stringeeClient.userId!)")
        AppStateManager.shared.convList?.title = "Connecting..."
    }
    
    func didFailWithError(_ stringeeClient: StringeeClient!, code: Int32, message: String!) {
        print("didFailWithError")
    }
    
    func requestAccessToken(_ stringeeClient: StringeeClient!) {
        print("requestAccessToken")
    }
    
    func didReceiveCustomMessage(_ stringeeClient: StringeeClient!, message: [AnyHashable : Any]!, fromUserId userId: String!) {
        print("didReceiveCustomMessage")
    }
}

extension StringeeImplement: StringeeIncomingCallDelegate {
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {
        
    }
}
