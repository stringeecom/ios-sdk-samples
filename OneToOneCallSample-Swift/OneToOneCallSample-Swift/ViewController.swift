//
//  ViewController.swift
//  OneToOneCallSample-Swift
//
//  Created by HoangDuoc on 6/3/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tfUserId: UITextField!
    @IBOutlet weak var switchCallType: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        InstanceManager.shared.viewController = self
    }

    @IBAction func makeCall1Tapped(_ sender: Any) {
        guard let userId = tfUserId.text, !userId.isEmpty else {
            show(msg: "You need to enter callee's userId")
            return
        }

        if !StringeeImplement.shared.stringeeClient.hasConnected {
            show(msg: "Not Connected")
            return
        }

        var callControl = CallControl()
        callControl.from = StringeeImplement.shared.stringeeClient.userId
        callControl.to = userId
        callControl.isVideo = switchCallType.isOn

        let callingVC = CallingViewController1.init(control: callControl, call: nil)
        callingVC.modalPresentationStyle = .fullScreen
        present(callingVC, animated: true, completion: nil)
    }

    @IBAction func makeCall2Tapped(_ sender: Any) {
        guard let userId = tfUserId.text, !userId.isEmpty else {
            show(msg: "You need to enter callee's userId")
            return
        }

        if !StringeeImplement.shared.stringeeClient.hasConnected {
            show(msg: "Not Connected")
            return
        }

        var callControl = CallControl()
        callControl.from = StringeeImplement.shared.stringeeClient.userId
        callControl.to = userId
        callControl.isVideo = switchCallType.isOn

        let callingVC = CallingViewController2.init(control: callControl, call: nil)
        callingVC.modalPresentationStyle = .fullScreen
        present(callingVC, animated: true, completion: nil)
    }

    private func show(msg: String) {
        let alert = UIAlertController(title: "Notification", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}


