/*
 - Kết nối tới Stringee Server
 - Xử lý các sự kiện liên quan đến kết nối
 */

import UIKit

let USER_ACCESS_TOKEN_KEY = "USER_ACCESS_TOKEN_KEY"

class StringeeImplement: NSObject {
    
    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()
    
    // Cần generate access token cho user trên trang dashboard của Stringee
    // ProjectId = 10795, appId = 9654
    var token = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS0xiT0Rpa3o4ZHBITGRvVU92c0lJYWdCTFZqUXNJOXdKLTE2NzgzMzQ2MjUiLCJpc3MiOiJTS0xiT0Rpa3o4ZHBITGRvVU92c0lJYWdCTFZqUXNJOXdKIiwiZXhwIjoxNjgwOTI2NjI1LCJ1c2VySWQiOiJpb3MtdW5pdC10ZXN0In0.7lk4K8wHn7R3yhyc1ru_TbKWoOWKXQMW43LvZhRr5z0"
    
    // push
    var voipToken: String?
    var remoteToken: String?
    var registeredTokenForVoipPush = false
    var registeredTokenForRemotePush = false

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
    
    func registerTokenForVoipPush(token: String? = "") {
        self.voipToken = token
        guard let pushToken = self.voipToken, !pushToken.isEmpty, !registeredTokenForVoipPush else {
            return
        }
        
        // Note: remember to pass isProduction depends on environment you are working on (development or production)
        self.stringeeClient.registerPush(forDeviceToken: pushToken, isProduction: false, isVoip: true) { (status, code, message) in
            print("registerPush: \(String(describing: message))")
            self.registeredTokenForVoipPush = status
        }
    }
    
    func registerTokenForRemotePush(token: String? = "") {
        self.remoteToken = token
        guard let pushToken = self.remoteToken, !pushToken.isEmpty, !registeredTokenForRemotePush else {
            return
        }
        
        // Note: remember to pass isProduction depends on environment you are working on (development or production)
        self.stringeeClient.registerPush(forDeviceToken: pushToken, isProduction: false, isVoip: false) { (status, code, message) in
            print("registerPush: \(String(describing: message))")
            self.registeredTokenForRemotePush = status
        }
    }
}

extension StringeeImplement: StringeeConnectionDelegate {
    
    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.callVC?.title = "Connected as \(stringeeClient.userId ?? "")"
        }
        registerTokenForVoipPush(token: self.voipToken)
        registerTokenForRemotePush(token: self.remoteToken);
        
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
