//
//  STEUIScreenExtensions.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/10/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import Foundation

extension UIScreen {
    
    static func getSafeAreaInsets() -> UIEdgeInsets {
        guard let rootView = UIApplication.shared.keyWindow else { return .zero }
        if #available(iOS 11.0, *) {
            return rootView.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    func widthOfSafeArea() -> CGFloat {
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }
        
        if #available(iOS 11.0, *) {
            let leftInset = rootView.safeAreaInsets.left
            let rightInset = rootView.safeAreaInsets.right
            
            return rootView.bounds.width - leftInset - rightInset
        } else {
            return rootView.bounds.width
        }
    }
    
    func heightOfSafeArea() -> CGFloat {
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }

        if #available(iOS 11.0, *) {
            let topInset = rootView.safeAreaInsets.top
            let bottomInset = rootView.safeAreaInsets.bottom
            return rootView.bounds.height - topInset - bottomInset
        } else {
            return rootView.bounds.height
        }
    }
    
}
