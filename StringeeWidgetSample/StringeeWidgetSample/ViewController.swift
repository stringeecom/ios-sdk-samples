//
//  ViewController.swift
//  StringeeWidgetSample
//
//  Created by HoangDuoc on 11/5/21.
//

import UIKit
import StringeeWidget
import Stringee

class ViewController: UIViewController {

    @IBOutlet weak var tfUserId: UITextField!
    
    let stringeeWidget = StringeeWidget.instance
    let accessToken = "YOUR_ACCESS_TOKEN"

    override func viewDidLoad() {
        super.viewDidLoad()
        stringeeWidget.delegate = self
        stringeeWidget.connect(token: accessToken)
    }

    @IBAction func voiceCallTapped(_ sender: Any) {
        call(isVideo: false)
    }
    
    @IBAction func videoCallTapped(_ sender: Any) {
        call(isVideo: true)
    }
    
    private func call(isVideo: Bool) {
        guard let to = tfUserId.text, !to.isEmpty else {
            return
        }
        
        let callConfig = StringeeCallConfig()
        callConfig.from = stringeeWidget.stringeeClient.userId
        // to is hostline if you want to call to your contact center
        callConfig.to = to
        callConfig.isVideoCall = isVideo
        callConfig.resolution = .hd
        stringeeWidget.makeCall(config: callConfig) { status, code, message, customData in
            print(message)
        }
    }
}

extension ViewController: StringeeWidgetDelegate {
    func onConnectionConnected(userId: String, isReconnecting: Bool) {
        print("onConnectionConnected")
        DispatchQueue.main.async {
            self.navigationItem.title = userId
        }
    }
    
    func onConnectionDisconnected(isReconnecting: Bool) {
        print("onConnectionDisconnected")
        DispatchQueue.main.async {
            self.navigationItem.title = "Connecting..."
        }
    }
    
    func onConnectionError(code: Int, message: String) {
        print("onConnectionError: \(message)")
    }
    
    func onRequestNewToken() {
        print("onRequestNewToken")
//        let newToken = "YOUR_NEW_ACCESS_TOKEN"
//        stringeeWidget.connect(token: newToken)
    }
    
    func onDisplayCallingViewController(vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    func onSignalingState(state: SignalingState) {
        print("onSignalingState: \(state.rawValue)")
        if state == .ended || state == .busy {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
