//
//  ViewController.swift
//  NewConferenceSample
//
//  Created by HoangDuoc on 8/10/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tfUserId: UITextField!
    @IBOutlet weak var btConnect: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Disconnected"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
    }

    deinit {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = nil
    }

    @IBAction func joinRoomTapped(_ sender: Any) {
        if !StringeeImplement.shared.stringeeClient.hasConnected {
            showNoti(msg: "Not connected")
            return
        }

        if StringeeImplement.shared.roomToken == nil {
            showNoti(msg: "Could not get room token")
            return
        }

        let conferenceVC = ConferenceViewController(nibName: "ConferenceViewController", bundle: nil)
        conferenceVC.modalPresentationStyle = .fullScreen
        present(conferenceVC, animated: true, completion: nil)
    }

    @IBAction func connectTapped(_ sender: Any) {
        guard let userId = self.tfUserId.text, !userId.isEmpty else {
            showNoti(msg: "You need to enter an userId")
            return
        }

        tfUserId.resignFirstResponder()
        StringeeImplement.shared.userId = userId
        StringeeImplement.shared.connectToStringeeServer()
    }

    private func showNoti(msg: String) {
        let alertVC = UIAlertController(title: "Notification", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertVC.addAction(cancelAction)
        present(alertVC, animated: true, completion: nil)
    }
}


