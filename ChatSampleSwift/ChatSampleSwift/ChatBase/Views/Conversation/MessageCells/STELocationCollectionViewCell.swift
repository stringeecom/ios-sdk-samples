//
//  STELocationCollectionViewCell.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/7/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import MapKit

class STELocationCollectionViewCell: STEBaseCollectionViewCell {
    
    var maskBubbleView: UIImageView?

    let ivLocation: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    var location: CLLocationCoordinate2D?
    var snapshotter: MKMapSnapshotter?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
//        bubbleView.layer.cornerRadius = STEMessageBubbleViewCornerRadius
//        bubbleView.clipsToBounds = true
        
        bubbleView.addSubview(ivLocation)
        bubbleView.addSubview(statusView)
        
//        ivLocation.layer.cornerRadius = STEMessageBubbleViewCornerRadius
        ivLocation.clipsToBounds = true
        
        // Layout
        ivLocation.snp.makeConstraints { (make) in
            make.edges.equalTo(bubbleView)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(STELocationCollectionViewCell.handleLocationTapped))
        ivLocation.addGestureRecognizer(tap)
        ivLocation.isUserInteractionEnabled = true
        
        statusView.snp.makeConstraints { (make) in
            make.bottom.equalTo(-STEMessageBubbleViewVerticalPadding)
            make.right.equalTo(-STEMessageBubbleViewHorizontalPadding)
            make.height.equalTo(STEMessageBubbleViewStatusViewHeight)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskBubbleView?.frame = ivLocation.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivLocation.image = nil
        location = nil
        self.snapshotter?.cancel()
    }
    
    // MARK: - Overide Message Presenting
    
    override func present(message: StringeeMessage, conv: StringeeConversation, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
        self.message = message
        super.present(message: message, conv: conv,  shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)

        updateBubbleWidth(width: STEBaseCollectionViewCell.cellSizeFor(message: message, conv: conv, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus).width)
        self.shouldDisplayAvatar(should: shouldDisplayAvatar)
        self.shouldDisplayMsgStatus(should: shouldDisplayMsgStatus)
        self.shouldDisplaySender(should: shouldDisplaySender)
        
        statusView.update(status: message.status, timeStamp: message.created, tintColor: .white)

        // Info
        guard let locationMsg = message as? StringeeLocationMessage else {
            return
        }
        
        location = CLLocationCoordinate2D(latitude: locationMsg.latitude, longitude: locationMsg.longitude)
        
        // Lấy về image trong cache nếu có
        let cacheIdentifier = String(format: "location-%f-%f", locationMsg.latitude, locationMsg.longitude)
        if let image = STEBaseCollectionViewCell.sharedImageCache.object(forKey: cacheIdentifier as AnyObject) as? UIImage {
            ivLocation.image = image
            return
        }
        
        // Snapshot image for location
        self.snapshotter = STELocationCollectionViewCell.snapshotter(location: location!)
        
        // Capture message cũ để so sánh
        weak var weakMsg = locationMsg
        
        self.snapshotter?.start(with: DispatchQueue.global(qos: .background), completionHandler: {[weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if error != nil || snapshot == nil {
                return
            }
            
            if let location = self.location, let locationImg = STEPinPhotoFor(snapshot: snapshot!, location: location) {
                // Cache lại
                STEBaseCollectionViewCell.sharedImageCache.setObject(locationImg, forKey: cacheIdentifier as AnyObject)
                
                // Nếu không phải cell cũ => ko set image
                if self.message?.localIdentifier != weakMsg?.localIdentifier {
                    return
                }
                
                // Update UI
                DispatchQueue.main.async {
                    self.ivLocation.image = locationImg
                    self.ivLocation.alpha = 0
                    UIView.animate(withDuration: 0.2, animations: {
                        self.ivLocation.alpha = 1
                    })
                }
            }
        })
    }
    
    override func shouldDisplayAvatar(should: Bool) {
        displayAvatar(should)
    }
    
    override func shouldDisplaySender(should: Bool) {
        if (should) {
        } else {
        }
    }
    
    override func shouldDisplayMsgStatus(should: Bool) {
        statusView.displayMsgStatus(should)
    }
    
    static func snapshotter(location: CLLocationCoordinate2D) -> MKMapSnapshotter {
        let options = MKMapSnapshotter.Options()
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        options.region = MKCoordinateRegion(center: location, span: span)
        options.scale = UIScreen.main.scale
        options.size = CGSize(width: STEMessageBubbleMapWidth, height: STEMessageBubbleMapHeight)
        return MKMapSnapshotter(options: options)
    }
    
    @objc private func handleLocationTapped() {
        if let location = self.location {
            self.delegate?.didTapLocation(cell: self, location: location)
        }
    }
}

class STELocationIncomingMessageCollectionViewCell: STELocationCollectionViewCell {
    
    static let identifier = "STELocationIncomingMessageCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        incomingCommonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        incomingCommonInit()
    }
    
    private func incomingCommonInit() {
        configureCellForMode(mode: .incoming)
        ivLocation.backgroundColor = STEColor.incomingBackground
        
        
        maskBubbleView = UIImageView(image: STEIncomingImage)
        ivLocation.mask = maskBubbleView
    }
    
//    override func present(message: StringeeMessage, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
//        super.present(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)

//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.incomingBackground, borderColor: STEColor.incomingBorder, isOutgoing: false)
//
//            let borderLayer = CAShapeLayer()
//            borderLayer.path = bubbleLayer.path
//            borderLayer.fillColor = nil
//            borderLayer.strokeColor = STEColor.incomingBorder.cgColor
//
//            DispatchQueue.main.async {
//                self.ivLocation.layer.mask = bubbleLayer
//                self.ivLocation.layer.sublayers?.removeAll()
//                self.ivLocation.layer.addSublayer(borderLayer)
//            }
//        }
        
//    }
}

class STELocationOutgoingMessageCollectionViewCell: STELocationCollectionViewCell {
    
    static let identifier = "STELocationOutgoingMessageCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        outgoingCommonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        outgoingCommonInit()
    }
    
    private func outgoingCommonInit() {
        configureCellForMode(mode: .outgoing)
        ivLocation.backgroundColor = STEColor.outgoingBackground
        
        maskBubbleView = UIImageView(image: STEOutgoingImage)
        ivLocation.mask = maskBubbleView
    }
    
//    override func present(message: StringeeMessage, shouldDisplayAvatar: Bool, shouldDisplaySender: Bool, shouldDisplayMsgStatus: Bool) {
//        super.present(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)

//        STEBaseCollectionViewCell.messageProcessingQueue.async {
//            let size = STEBaseCollectionViewCell.cellSizeFor(message: message, shouldDisplayAvatar: shouldDisplayAvatar, shouldDisplaySender: shouldDisplaySender, shouldDisplayMsgStatus: shouldDisplayMsgStatus)
//            let realHeight = size.height - STEMessageBubbleViewVerticalMargin * 2
//            let bubbleLayer = self.bubbleView.layerForBubble(message: message, width: size.width, height: realHeight, backColor: STEColor.outgoingBackground, borderColor: STEColor.outgoingBorder, isOutgoing: true)
//
//            let borderLayer = CAShapeLayer()
//            borderLayer.path = bubbleLayer.path
//            borderLayer.fillColor = nil
//            borderLayer.strokeColor = STEColor.outgoingBorder.cgColor
//
//            DispatchQueue.main.async {
//                self.ivLocation.layer.mask = bubbleLayer
//                self.ivLocation.layer.sublayers?.removeAll()
//                self.ivLocation.layer.addSublayer(borderLayer)
//            }
//        }
//    }
}
