//
//  STERecordButton.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 5/13/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import SnapKit

let STERecordButtonAnimationDuration: Double = 0.3

class STERecordButton: UIButton {

    var pathLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        pathLayer = CAShapeLayer()
        pathLayer.path = currentInnerPath().cgPath
        pathLayer.strokeColor = nil
        pathLayer.fillColor = UIColor.red.cgColor
        self.layer.addSublayer(pathLayer)
        
        self.snp.makeConstraints { (make) in
            make.width.equalTo(66)
            make.height.equalTo(66)
        }
        
        // Clear the title
        self.setTitle("", for: .normal)
        
        self.addTarget(self, action: #selector(STERecordButton.touchUpInside(sender:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(STERecordButton.touchDown(sender:)), for: .touchDown)
    }
    
    override func prepareForInterfaceBuilder() {
        self.setTitle("", for: .normal)
    }
    
    override func draw(_ rect: CGRect) {
        let outerRing = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 60, height: 60))
        outerRing.lineWidth = 6
        UIColor.white.setStroke()
        outerRing.stroke()
    }
    
    override var isSelected: Bool {
        willSet {
            super.isSelected = newValue
            let morph = CABasicAnimation(keyPath: "path")
            morph.duration = STERecordButtonAnimationDuration
            morph.toValue = currentInnerPath().cgPath
            morph.fillMode = .forwards
            morph.isRemovedOnCompletion = false
            morph.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pathLayer.add(morph, forKey: "")
        }
        
        didSet {
            
        }
    }
    
    @objc func touchUpInside(sender: UIButton) {
        let colorChange = CABasicAnimation(keyPath: "fillColor")
        colorChange.duration = STERecordButtonAnimationDuration
        colorChange.toValue = UIColor.red.cgColor
        colorChange.fillMode = .forwards
        colorChange.isRemovedOnCompletion = false
        colorChange.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pathLayer.add(colorChange, forKey: "darkColor")
        isSelected = !isSelected
    }
    
    @objc func touchDown(sender: UIButton) {
        let morph = CABasicAnimation(keyPath: "fillColor")
        morph.duration = STERecordButtonAnimationDuration
        morph.toValue = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5).cgColor
        morph.fillMode = .forwards
        morph.isRemovedOnCompletion = false
        morph.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pathLayer.add(morph, forKey: "")
    }
    

    private func currentInnerPath() -> UIBezierPath {
        if isSelected {
            return innerSquarePath()
        } else {
            return innerCirclePath()
        }
    }
    
    private func innerCirclePath() -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x: 8, y: 8, width: 50, height: 50), cornerRadius: 25)
    }
    
    private func innerSquarePath() -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x: 18, y: 18, width: 30, height: 30), cornerRadius: 4)
    }
}
