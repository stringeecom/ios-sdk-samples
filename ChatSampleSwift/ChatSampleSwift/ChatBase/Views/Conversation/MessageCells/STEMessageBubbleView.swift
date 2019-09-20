//
//  STEMessageBubbleView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

let STEMessageBubbleViewCornerRadius: CGFloat = 17.0

let STEMessageBubbleViewLabelNameHeight: CGFloat = 18.0
let STEMessageBubbleViewLabelNameBottomMargin: CGFloat = 6.0

let STEMessageBubbleViewStatusViewHeight: CGFloat = 20.0

let STEMessageBubbleViewVerticalMargin: CGFloat = 2.0
//let STEMessageBubbleViewHorizontalMargin: CGFloat = 6.0
let STEMessageBubbleViewHorizontalMargin: CGFloat = 2.0 // Giảm xuống để cho bubble gần lề

//let STEMessageBubbleViewHorizontalPadding: CGFloat = 8.0
let STEMessageBubbleViewHorizontalPadding: CGFloat = 12.0 // Tăng lên để đỡ bị clip
let STEMessageBubbleViewVerticalPadding: CGFloat = 6.0

let STEMessageBubbleMapWidth: CGFloat = 200.0
let STEMessageBubbleMapHeight: CGFloat = 200.0

let STEMessageBubbleContactWidth: CGFloat = 200.0
let STEMessageBubbleContactHeight: CGFloat = 125.0

let STEMessageBubbleFileWidth: CGFloat = 200.0
let STEMessageBubbleFileHeight: CGFloat = 80.0

let STEMessageBubbleAudioWidth: CGFloat = 200.0
let STEMessageBubbleAudioHeight: CGFloat = 90.0

let STEMessageBubbleStickerWidth: CGFloat = 150.0
let STEMessageBubbleStickerHeight: CGFloat = 160.0

let STEOutgoingImage = UIImage(named: "outgoing-message-bubble")?.resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
let STEIncomingImage = UIImage(named: "incoming-message-bubble")?.resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch).withRenderingMode(.alwaysTemplate)


class STEMessageBubbleView: UIView {
    
    static let sharedLayerCache = NSCache<AnyObject, AnyObject>()
    
    let progressView: STEProgressView = {
        let proView = STEProgressView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        proView.isHidden = true // mặc định là ẩn
        return proView
    }()
        
    init() {
        super.init(frame: .zero)
        addSubview(progressView)
        
        progressView.snp.makeConstraints { (make) in
            make.center.equalTo(self.snp.center)
            make.width.equalTo(45)
            make.height.equalTo(45)
        }
        
//        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bringSubviewToFront(progressView)
    }
    
    func layerForBubble(message: StringeeMessage, width: CGFloat, height: CGFloat, backColor: UIColor, borderColor: UIColor, isOutgoing: Bool) -> CAShapeLayer {
        if let localId = message.localIdentifier, let serverId = message.identifier, let layer = STEMessageBubbleView.sharedLayerCache.object(forKey: (localId + serverId) as AnyObject) as? CAShapeLayer {
//            print("========= Đã lấy được layer from cache")
            return layer
        }
        
        let bezierPath = UIBezierPath()
        if isOutgoing {
            bezierPath.move(to: CGPoint(x: width - 22, y: height))
            bezierPath.addLine(to: CGPoint(x: 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height - 17), controlPoint1: CGPoint(x: 7.61, y: height), controlPoint2: CGPoint(x: 0, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: 0, y: 17))
            bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: width - 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: width - 4, y: 17), controlPoint1: CGPoint(x: width - 11.61, y: 0), controlPoint2: CGPoint(x: width - 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: width - 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 4, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
            bezierPath.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: width - 11.04, y: height - 4.04), controlPoint1: CGPoint(x: width - 4.07, y: height + 0.43), controlPoint2: CGPoint(x: width - 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: width - 22, y: height), controlPoint1: CGPoint(x: width - 16, y: height), controlPoint2: CGPoint(x: width - 19, y: height))
        } else {
            bezierPath.move(to: CGPoint(x: 22, y: height))
            bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: width, y: 17))
            bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
            bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
        }
        bezierPath.close()
        
        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        layer.fillColor = backColor.cgColor
        layer.strokeColor = borderColor.cgColor
        
        // Cache lai layer
        if let localId = message.localIdentifier, let serverId = message.identifier {
            STEMessageBubbleView.sharedLayerCache.setObject(layer, forKey: (localId + serverId) as AnyObject)
        }
        
        return layer
    }
}
