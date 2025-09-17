//
//  Stringeeimplement.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

let USER_ID_KEY = "USER_ID_KEY"

let user1 = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS3JTaWZRWlVJa3ZPY2Q0RHdZT2c1Y2lpQUJma01kTTJOLTE3NTM3NzUyMDgiLCJpc3MiOiJTS3JTaWZRWlVJa3ZPY2Q0RHdZT2c1Y2lpQUJma01kTTJOIiwiZXhwIjoxNzUzODYxNjA4LCJ1c2VySWQiOiJBQzgyODFGNkhXIiwiaWNjX2FwaSI6dHJ1ZSwiY2hhdEFnZW50Ijp0cnVlLCJkaXNwbGF5TmFtZSI6InRhaXB2IiwiYXZhdGFyVXJsIjoiXC9cL2FzaWEtMS1maWxlc2VydmVyLTIuc3RyaW5nZWUuY29tXC8wXC9hc2lhLTFfMV9PUE40MDdDOENTRlpUUkdcL1lXUVlPV1ZHWEItMTcxNTc1OTc2MTExNy5qcGciLCJzdWJzY3JpYmUiOiJBTExfQ0FMTF9TVEFUVVMsb25saW5lX3N0YXR1c19HUkZKNjRHTSxhZ2VudF9tYW51YWxfc3RhdHVzIiwiYXR0cmlidXRlcyI6Ilt7XCJhdHRyaWJ1dGVcIjpcIm9ubGluZVN0YXR1c1wiLFwidG9waWNcIjpcIm9ubGluZV9zdGF0dXNfR1JGSjY0R01cIn0se1wiYXR0cmlidXRlXCI6XCJjYWxsXCIsXCJ0b3BpY1wiOlwiY2FsbF9HUkZKNjRHTVwifV0ifQ.vgaRFXOkKLxO-xAxUTfxAIsaLf0njRCfWGO5CrUMNPM"
let user2 = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyLTE1OTY1Mjg1MTIiLCJpc3MiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyIiwiZXhwIjoxNTk5MTIwNTEyLCJ1c2VySWQiOiJWaWV0Y29tYmFuazIifQ.0L5L1cCtc3hDHerXymjhv22ZCk5ST-xn1k8JpM8UmBI"

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
