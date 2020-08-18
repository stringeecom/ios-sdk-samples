//
//  ViewController.swift
//  CallkitSample-iOS13
//
//  Created by HoangDuoc on 8/17/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tfUserId: UITextField!
    @IBOutlet weak var btCall: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        InstanceManager.shared.viewController = self
    }
    
    @IBAction func callTapped(_ sender: Any) {
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
        
        let callingVC = CallingViewController.init(control: callControl, call: nil)
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

