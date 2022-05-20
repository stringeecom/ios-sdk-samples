//
//  AppDelegate.swift
//  OneToOneCallSample-Swift
//
//  Created by HoangDuoc on 6/3/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        StringeeImplement.shared.connectToStringeeServer()
        return true
    }
}


