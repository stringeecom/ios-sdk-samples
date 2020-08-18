/*
 - Kết nối tới Stringee Server
 - Xử lý các sự kiện liên quan đến kết nối
 */

import UIKit

let userToken1 = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyLTE1OTc2NTMwMTEiLCJpc3MiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyIiwiZXhwIjoxNjAwMjQ1MDExLCJ1c2VySWQiOiJ1c2VyMSJ9.xF-EeN6q_6QXgP39gq0j1LifHjlsyZjCAccgq7PUb5g"
let userToken2 = "eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyLTE1OTc2NTMwMjAiLCJpc3MiOiJTS0xIb2NCdDl6Qk5qc1pLeThZaUVkSzRsU3NBZjhCSHpyIiwiZXhwIjoxNjAwMjQ1MDIwLCJ1c2VySWQiOiJ1c2VyMiJ9.IF72MicpngLgX4TZI5TL6sL7R3JeeTqEAN8lu1MO4GE"

class StringeeImplement: NSObject {
    
    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()
    
    var token: String?
    var connectWithToken1 = true
    
    // push
    var pushToken: String?
    var registeredTokenForPush = false
    
    private override init() {
        super.init()
        stringeeClient.connectionDelegate = self;
        stringeeClient.incomingCallDelegate = self
        token = connectWithToken1 ? userToken1 : userToken2
    }
    
    func connectToStringeeServer() {
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
            InstanceManager.shared.viewController?.title = "Connected as \(stringeeClient.userId ?? "")"
        }
        
        CallManager.shared.startCheckingReceivingTimeoutOfStringeeCall()
    }
    
    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.viewController?.title = "Disconnected"
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
        CallManager.shared.handleIncomingCallEvent(stringeeCall: stringeeCall)
    }
}
