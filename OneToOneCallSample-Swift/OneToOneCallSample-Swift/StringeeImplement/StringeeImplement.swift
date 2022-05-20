/*
 - Kết nối tới Stringee Server
 - Xử lý các sự kiện liên quan đến kết nối
 */

import UIKit

let userToken1 = "TOKEN-FOR-USER1"
let userToken2 = "TOKEN-FOR-USER2"

class StringeeImplement: NSObject {

    static let shared = StringeeImplement()
    let stringeeClient = StringeeClient()

    var token: String?
    var connectWithToken1 = true

    private override init() {
        super.init()
        stringeeClient.connectionDelegate = self;
        stringeeClient.incomingCallDelegate = self

        token = connectWithToken1 ? userToken1 : userToken2
    }

    func connectToStringeeServer() {
        stringeeClient.connect(withAccessToken: token)
    }
}

extension StringeeImplement: StringeeConnectionDelegate {

    func didConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.viewController?.title = "Connected as \(stringeeClient.userId ?? "")"
        }
    }

    func didDisConnect(_ stringeeClient: StringeeClient!, isReconnecting: Bool) {
        print("didDisConnect \(stringeeClient.userId!)")
        DispatchQueue.main.async {
            InstanceManager.shared.viewController?.title = "Disconnected"
        }
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
    // Call 1
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall: StringeeCall!) {
        DispatchQueue.main.async {
            if (InstanceManager.shared.callingVC1 != nil || InstanceManager.shared.callingVC2 != nil) {
                // Đang trong cuộc gọi khác => từ chối cuộc mới
                stringeeCall.reject { (status, code, message) in
                    print(message ?? "")
                }
                return
            }

            let callControl = CallControl()
            let callingVC = CallingViewController1.init(control: callControl, call: stringeeCall)
            callingVC.modalPresentationStyle = .fullScreen
            UIApplication.shared.keyWindow?.rootViewController?.present(callingVC, animated: true, completion: nil)
        }
    }

    // Call 2
    func incomingCall(with stringeeClient: StringeeClient!, stringeeCall2: StringeeCall2!) {
        DispatchQueue.main.async {
            if (InstanceManager.shared.callingVC1 != nil || InstanceManager.shared.callingVC2 != nil) {
                // Đang trong cuộc gọi khác => từ chối cuộc mới
                stringeeCall2.reject { (status, code, message) in
                    print(message ?? "")
                }
                return
            }

            let callControl = CallControl()
            let callingVC = CallingViewController2.init(control: callControl, call: stringeeCall2)
            callingVC.modalPresentationStyle = .fullScreen
            UIApplication.shared.keyWindow?.rootViewController?.present(callingVC, animated: true, completion: nil)
        }
    }
}

