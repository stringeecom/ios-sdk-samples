//
//  STEProgressView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/3/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

protocol STEProgressViewDelegate: AnyObject {
    func didTapDownloadButton(view: STEProgressView)
}

class STEProgressView: UIView {

    var borderWidth: CGFloat = 5.0
    var animationDuration: TimeInterval = 0.25
    var backgroundRingColor = UIColor(white: 0.8, alpha: 0.5)
    var foregroundRingColor = UIColor(white: 1.0, alpha: 0.8)
    var radius: CGFloat {
        return Swift.min(self.bounds.size.width, self.bounds.size.height) / 2
    }
    var progress: CGFloat = 0.0
    
    lazy var backRingLayer = CAShapeLayer()
    lazy var progressRingLayer = CAShapeLayer()

    let downloadButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "download_icon"), for: .normal)
        return button
    }()
    
    weak var delegate: STEProgressViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        layer.addSublayer(backRingLayer)
        layer.addSublayer(progressRingLayer)
        
        addSubview(downloadButton)
        downloadButton.addTarget(self, action: #selector(STEProgressView.handleDownloadTapped), for: .touchUpInside)
        downloadButton.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds = self.bounds
        
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: self.radius - self.borderWidth * 0.5, startAngle: STEDegreeToRadius(degree: 0 - 90), endAngle: STEDegreeToRadius(degree: 360 - 90), clockwise: true)
        
        progressRingLayer.frame = self.bounds
        progressRingLayer.lineWidth = borderWidth
        progressRingLayer.path = path.cgPath
        progressRingLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        progressRingLayer.fillColor = UIColor.clear.cgColor
        progressRingLayer.position = CGPoint(x: self.layer.frame.width * 0.5, y: self.layer.frame.height * 0.5)
        progressRingLayer.strokeEnd = progress
        progressRingLayer.strokeColor = foregroundRingColor.cgColor
        
        backRingLayer.frame = self.bounds
        backRingLayer.lineWidth = borderWidth
        backRingLayer.path = path.cgPath
        backRingLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backRingLayer.fillColor = UIColor.clear.cgColor
        backRingLayer.position = CGPoint(x: self.layer.frame.width * 0.5, y: self.layer.frame.height * 0.5)
        backRingLayer.strokeEnd = 1.0
        backRingLayer.strokeColor = backgroundRingColor.cgColor
    }

    // MARK: - Actions
    
    func setProgress(_ pro: CGFloat, animated: Bool) {
        if animated {
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.duration = self.animationDuration
            strokeEndAnimation.fillMode = .forwards
            strokeEndAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
            strokeEndAnimation.isRemovedOnCompletion = true
            strokeEndAnimation.fromValue = NSNumber(floatLiteral: Double(self.progress))
            strokeEndAnimation.toValue = NSNumber(floatLiteral: Double(pro))
            progressRingLayer.add(strokeEndAnimation, forKey: "progressStatus")
        }
        
        progressRingLayer.strokeEnd = pro
        progress = pro
        
        self.downloadButton.isHidden = true
        self.isHidden = pro == 1.0
    }
    
    @objc private func handleDownloadTapped() {
        self.delegate?.didTapDownloadButton(view: self)
    }
}
