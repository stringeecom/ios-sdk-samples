//
//  Stringeeimplement.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit


class StringeeImplement: NSObject {

    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()

    var userId: String!
    var token = "YOUR_ACCESS_TOKEN"
    var roomToken = "YOUR_ROOM_TOKEN"

    private override init() {
        super.init()
        stringeeClient.connectionDelegate = self;
    }

    func connectToStringeeServer() {
        stringeeClient.connect(withAccessToken: token)
    }
}

extension StringeeImplement: StringeeConnectionDelegate {

    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.viewController?.btConnect.isEnabled = false
            appDelegate.viewController?.title = "Connected as \(stringeeClient.userId ?? "")"
        }
    }

    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.viewController?.btConnect.isEnabled = true
            appDelegate.viewController?.title = "Connecting..."
        }
    }

    func didFailWithError(_ stringeeClient: StringeeClient!, code: Int32, message: String!) {
        print("didFailWithError")
    }

    func requestAccessToken(_ stringeeClient: StringeeClient!) {
        print("requestAccessToken")
        stringeeClient.connect(withAccessToken: token ?? "")
    }

    func didReceiveCustomMessage(_ stringeeClient: StringeeClient!, message: [AnyHashable : Any]!, fromUserId userId: String!) {
        print("didReceiveCustomMessage")
    }
}

extension StringeeImplement: StringeeIncomingCallDelegate {
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {

    }
}

