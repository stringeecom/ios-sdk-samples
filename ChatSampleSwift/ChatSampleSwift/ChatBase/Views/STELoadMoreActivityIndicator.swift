//
//  STELoadMoreActivityIndicatorView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/25/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class STELoadMoreActivityIndicator {
    private let spacingFromLastCell: CGFloat
    private let spacingFromLastCellWhenLoadMoreActionStart: CGFloat
    private weak var activityIndicatorView: UIActivityIndicatorView?
    private weak var scrollView: UIScrollView? // Cái scrollview mà nó sẽ hoạt động trong

    private var defaultY: CGFloat {
        guard let height = scrollView?.contentSize.height else { return 0.0 }
        return height + spacingFromLastCell
    }
    
    init (scrollView: UIScrollView, spacingFromLastCell: CGFloat, spacingFromLastCellWhenLoadMoreActionStart: CGFloat) {
        self.scrollView = scrollView
        self.spacingFromLastCell = spacingFromLastCell
        self.spacingFromLastCellWhenLoadMoreActionStart = spacingFromLastCellWhenLoadMoreActionStart
        let size:CGFloat = 40
        let frame = CGRect(x: (scrollView.frame.width-size)/2, y: scrollView.contentSize.height + spacingFromLastCell, width: size, height: size)
        let activityIndicatorView = UIActivityIndicatorView(frame: frame)
        activityIndicatorView.color = .black
        activityIndicatorView.isHidden = false
        activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = isHidden
        self.activityIndicatorView = activityIndicatorView
    }
    
    // Nếu scrollview không tồn tại hoặc contentsize nhỏ hơn frame thì không hiển thị
    private var isHidden: Bool {
        guard let scrollView = scrollView else { return true }
        return scrollView.contentSize.height < scrollView.frame.size.height
    }
    
    func start(closure: @escaping ()->()) {
        DispatchQueue.main.async {
            guard let scrollView = self.scrollView, let activityIndicatorView = self.activityIndicatorView else { return }
            if activityIndicatorView.isAnimating {
                return
            }
            
            let offsetY = scrollView.contentOffset.y
            activityIndicatorView.isHidden = self.isHidden
            if !self.isHidden && offsetY >= 0 {
                let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
                let offsetDelta = offsetY - contentDelta
                
                let newY = self.defaultY-offsetDelta
                if newY < scrollView.frame.height {
                    activityIndicatorView.frame.origin.y = newY
                } else {
                    if activityIndicatorView.frame.origin.y != self.defaultY {
                        activityIndicatorView.frame.origin.y = self.defaultY
                    }
                }
                
                if !activityIndicatorView.isAnimating {
                    if offsetY > contentDelta && offsetDelta >= self.spacingFromLastCellWhenLoadMoreActionStart && !activityIndicatorView.isAnimating {
                        activityIndicatorView.startAnimating()
                        closure()
                    }
                }
                
                if scrollView.isDecelerating {
                    if activityIndicatorView.isAnimating && scrollView.contentInset.bottom == 0 {
                        UIView.animate(withDuration: 0.3) { [weak self] in
                            if let bottom = self?.spacingFromLastCellWhenLoadMoreActionStart {
                                scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func stop() {
        DispatchQueue.main.async {
            guard let scrollView = self.scrollView , let activityIndicatorView = self.activityIndicatorView else { return }
            let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
            let offsetDelta = scrollView.contentOffset.y - contentDelta
            if offsetDelta >= 0 {
                UIView.animate(withDuration: 0.3) {
                    scrollView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
                }
            } else {
                scrollView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
            }
            
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
        }
    }
}
