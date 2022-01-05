/*
 - Kết nối tới Stringee Server
 - Xử lý các sự kiện liên quan đến kết nối
 */

import UIKit

let USER_ACCESS_TOKEN_KEY = "USER_ACCESS_TOKEN_KEY"

class StringeeImplement: NSObject {
    
    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()
    
    var token = "" // Cần generate access token cho user trên trang dashboard của Stringee
    
    // push
    var pushToken: String?
    var registeredTokenForPush = false
    
    private override init() {
        super.init()
        stringeeClient.connectionDelegate = self
        stringeeClient.incomingCallDelegate = self
        if (token.isEmpty) {
            token = (UserDefaults.standard.object(forKey: USER_ACCESS_TOKEN_KEY) as? String) ?? ""
        }
    }
    
    func connectToStringeeServer() {
        if (token.isEmpty) {
            print("Không thể kết nối tới Stringee Server vì không có access token")
            return
        }
        
        UserDefaults.standard.setValue(token, forKey: USER_ACCESS_TOKEN_KEY)
        stringeeClient.connect(withAccessToken: token)
    }
    
    func registerTokenForPush(token: String? = "") {
        self.pushToken = token
        guard let pushToken = self.pushToken, !pushToken.isEmpty, !registeredTokenForPush else {
            return
        }
        
        // Note: remember to pass isProduction depends on environment you are working on (development or production)
        self.stringeeClient.registerPush(forDeviceToken: pushToken, isProduction: false, isVoip: true) { (status, code, message) in
            print("registerPush: \(String(describing: message))")
            self.registeredTokenForPush = status
        }
    }
}

extension StringeeImplement: StringeeConnectionDelegate {
    
    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.callVC?.title = "Connected as \(stringeeClient.userId ?? "")"
        }
        registerTokenForPush(token: self.pushToken)
        
        CallManager.shared.startCheckingReceivingTimeoutOfStringeeCall()
    }
    
    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.callVC?.title = "Disconnected"
        }
        CallManager.shared.stopCheckingReceivingTimeoutOfStringeeCall()
    }
    
    func didFailWithError(_ stringeeClient: StringeeClient!, code: Int32, message: String!) {
        print("didFailWithError")
    }
    
    func requestAccessToken(_ stringeeClient: StringeeClient!) {
        print("requestAccessToken")
        stringeeClient.connect(withAccessToken: token)
    }
    
    func didReceiveCustomMessage(_ stringeeClient: StringeeClient!, message: [AnyHashable : Any]!, fromUserId userId: String!) {
        print("didReceiveCustomMessage")
    }
}

extension StringeeImplement: StringeeIncomingCallDelegate {
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {
        
    }
    
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall2: StringeeCall2!) {
        CallManager.shared.handleIncomingCallEvent(stringeeCall: stringeeCall2)
    }
    
}
