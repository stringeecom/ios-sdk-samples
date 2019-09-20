//
//  STEConversationView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEConversationView: UIView {
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    private func commonInit() {
        self.backgroundColor = UIColor.white
    }
    
}
