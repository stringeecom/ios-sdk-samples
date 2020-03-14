//
//  HomeViewController.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var userIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func callButtonHandler(_ sender: UIButton) {
        guard let toNumber = userIdTextField.text, !toNumber.isEmpty else { return }
        StringeeCallCenter.shared.makeCall(to: toNumber) { (success, message) in
            print("makeCallWithCompletionHandler \(message ?? "")")
            if !success {
                print("Cuộc gọi không thành công")
            }
        }
    }
}

extension HomeViewController: StringeeCallDelegate {
    func didChangeSignalingState(_ stringeeCall: StringeeCall!, signalingState: SignalingState, reason: String!, sipCode: Int32, sipReason: String!) {
        print("didChangeSignalingState")
    }
    
    func didChangeMediaState(_ stringeeCall: StringeeCall!, mediaState: MediaState) {
        print("didChangeMediaState")
    }
}
