//
//  InstanceManager.swift
//  CallkitSample-iOS13
//
//  Created by HoangDuoc on 8/17/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import Foundation

class InstanceManager {
    static let shared = InstanceManager()

    var callVC: CallViewController?
    var callingVC: CallingViewController?
    
    /*
     Fix bug không thể present ViewController trong background trên iOS 15. Trong trường hợp show màn hình CallingViewController khi có cuộc gọi đến
     Cách fix: Tạo UIWindow với rootViewController là ViewController cần present
     **/
    var overlayWindow: UIWindow?
    
    func showOverlayWindow(vc: UIViewController) {
        overlayWindow = createWindow()
        overlayWindow?.windowLevel = .statusBar + 1
        overlayWindow?.rootViewController = vc
        overlayWindow?.isHidden = false
    }
    
    func hideOverlayWindow() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
    
    func createWindow() -> UIWindow {
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).first as? UIWindowScene {
                return UIWindow.init(windowScene: scene)
            } else {
                return UIWindow.init(frame: UIScreen.main.bounds)
            }
        } else {
            return UIWindow.init(frame: UIScreen.main.bounds)
        }
    }
}
