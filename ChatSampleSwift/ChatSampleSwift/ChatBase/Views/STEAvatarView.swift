//
//  STEAvatarView.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/17/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import UIKit

class STEAvatarView: UIView {
    // MARK: - Variables
    
    static let sharedImageCache = NSCache<AnyObject, AnyObject>()
    
    weak var avatarItem: STEAvatarItem?
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = STEColor.darkGray
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        // Add subview
        self .addSubview(self.imageView)
        
        // Layout Image
        self.imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        let imageViewDiameter = Swift.min(frame.width, frame.height)
        self.imageView.layer.cornerRadius = imageViewDiameter * 0.5
        imageView.sd_imageTransition = .fade

//        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
        // Add subview
        self .addSubview(self.imageView)
        
        // Layout Image
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageViewDiameter = Swift.min(self.imageView.bounds.width, self.imageView.bounds.height)
        self.imageView.layer.cornerRadius = imageViewDiameter * 0.5
    }
    
    // MARK: - Presentation
    
    func present(avatarItem: STEAvatarItem) {
        self.imageView.image = nil
        self.avatarItem = avatarItem
    
        if let avatarImageUrl = avatarItem.avatarImageUrl {
            self.imageView.sd_setImage(with: avatarImageUrl)
        } else if let avatarInitials = avatarItem.avatarInitials {
            self.imageView.image = self.getAvatarImageWithString(str: avatarInitials)
        }
    }
    
    func reset() {
        self.imageView.image = nil
        self.avatarItem = nil
    }
    
    func getAvatarImageWithString(str: String) -> UIImage? {
        if let image: UIImage = STEAvatarView.sharedImageCache.object(forKey: str as AnyObject) as? UIImage {
            return image
        } else if let genImage = str.toPresentativeImage() {
            STEAvatarView.sharedImageCache.setObject(genImage, forKey: str as AnyObject)
            return genImage
        }
        
        return nil
    }
    
    
}

