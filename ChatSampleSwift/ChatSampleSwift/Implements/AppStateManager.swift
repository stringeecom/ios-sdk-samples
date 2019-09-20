//
//  STEAppStateManager.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class AppStateManager: NSObject {
    static let shared = AppStateManager()
    
    var convList: SampleConversationListViewController?
    
    private override init() {
        
    }
}
