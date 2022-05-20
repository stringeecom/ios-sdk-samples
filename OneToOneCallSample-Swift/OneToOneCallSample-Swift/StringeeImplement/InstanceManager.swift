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

    var viewController: ViewController?
    var callingVC1: CallingViewController1?
    var callingVC2: CallingViewController2?
}

