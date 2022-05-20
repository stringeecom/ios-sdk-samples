//
//  ListVideoView.swift
//  NewConferenceSample
//
//  Created by HoangDuoc on 8/10/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import UIKit

protocol ListVideoViewDelegate {
    func videoViewTapped(videoView: StringeeVideoView)
}

class ListVideoView: UIScrollView {
    let space = 5
    let viewWidth = 120
    var videoViews = [StringeeVideoView]()
    var videoViewDelegate: ListVideoViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
    }

    func add(videoView: StringeeVideoView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoViews.insert(videoView, at: 0)
            self.addSubview(videoView)

            let gesture = UITapGestureRecognizer(target: self, action: #selector(ListVideoView.videoViewTapped(gesture:)))
            videoView.addGestureRecognizer(gesture)

            self.layoutVideoViews()
        }
    }

    func remove(videoView: StringeeVideoView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoViews.removeAll { (loopView) -> Bool in
                return loopView === videoView
            }

            if let _ = videoView.superview {
                videoView.removeFromSuperview()
            }
            self.layoutVideoViews()
        }
    }

    private func layoutVideoViews() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            let viewCount = self.videoViews.count
            let totalVideoWidth = viewCount * self.viewWidth
            let totalSpacing = (viewCount - 1) * self.space
            let contentWidth = totalVideoWidth + totalSpacing
            let viewHeight = Int(self.frame.size.height)
            self.contentSize = CGSize(width: contentWidth, height: viewHeight)

            for (index, loopView) in self.videoViews.enumerated() {
                let originX = index * (self.viewWidth + self.space)
                loopView.frame = CGRect(x: originX, y: 0, width: self.viewWidth, height: Int(self.frame.size.height))
            }
        }, completion: nil)

    }

    @objc private func videoViewTapped(gesture: UITapGestureRecognizer) {
        if let videoView = gesture.view as? StringeeVideoView {
            videoView.removeGestureRecognizer(gesture)
            videoViewDelegate?.videoViewTapped(videoView: videoView)
        }
    }

}

