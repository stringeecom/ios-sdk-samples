//
//  CallViewController.swift
//  CallkitSample-iOS13
//
//  Created by HoangDuoc on 9/7/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import UIKit

class CallViewController: UIViewController {
    
    @IBOutlet weak var tfUserId: UITextField!
    @IBOutlet weak var switchVideoMode: UISwitch!
    var connected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        InstanceManager.shared.callVC = self
        title = "Connecting..."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !connected {
            connected = !connected
            StringeeImplement.shared.connectToStringeeServer()
        }
    }
    
    @IBAction func callTapped(_ sender: Any) {
        guard let userId = tfUserId.text, !userId.isEmpty else {
            show(msg: "You need to enter callee's userId", inVC: self)
            return
        }
        
        if !StringeeImplement.shared.stringeeClient.hasConnected {
            show(msg: "Not Connected", inVC: self)
            return
        }
        
        var callControl = CallControl()
        callControl.from = StringeeImplement.shared.stringeeClient.userId
        callControl.to = userId
        callControl.isVideo = switchVideoMode.isOn
        
        let callingVC = CallingViewController.init(control: callControl, call: nil)
        InstanceManager.shared.showOverlayWindow(vc: callingVC)
    }
    
    func show(msg: String, inVC: UIViewController) {
        let alert = UIAlertController(title: "Notification", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        inVC.present(alert, animated: true, completion: nil)
    }
}
