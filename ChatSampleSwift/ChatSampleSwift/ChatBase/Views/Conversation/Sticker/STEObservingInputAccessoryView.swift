//
//  STEObservingInputAccessoryView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 5/6/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

protocol STEObservingInputAccessoryViewDelegate: AnyObject {
    func didChangeCenter(newCenter: CGPoint, observingView: STEObservingInputAccessoryView)
}

class STEObservingInputAccessoryView: UIView {
    
    weak var delegate: STEObservingInputAccessoryViewDelegate?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        self.superview?.removeObserver(self, forKeyPath: "center")
//        self.superview?.removeObserver(self, forKeyPath: "bounds")

        newSuperview?.addObserver(self, forKeyPath: "center", options: [.prior], context: nil)
//        newSuperview?.addObserver(self, forKeyPath: "bounds", options: [.new], context: nil)
        super.willMove(toSuperview: newSuperview)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "center" {
            let priorCenter = change?[.notificationIsPriorKey] as? CGPoint ?? .zero
            let center = change?[.newKey] as? CGPoint ?? .zero

            self.delegate?.didChangeCenter(newCenter: center, observingView: self)
        }
    }
}
