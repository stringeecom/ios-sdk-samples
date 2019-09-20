//
//  STEStickerCollectionViewCell.swift
//  IVND
//
//  Created by HoangDuoc on 5/15/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class STEStickerCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "STEStickerCollectionViewCell"
    let ivSticker: UIImageView = {
        let iv = UIImageView ()
        iv.backgroundColor = .clear
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(ivSticker)
        ivSticker.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    deinit {
        self.ivSticker.image = nil
    }
    
    func configure(imagePath: String) {
        if let image: UIImage = STEBaseCollectionViewCell.sharedImageCache.object(forKey: imagePath as AnyObject) as? UIImage {
            ivSticker.image = image
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let image = UIImage(contentsOfFile: imagePath) {
                STEBaseCollectionViewCell.sharedImageCache.setObject(image, forKey: imagePath as AnyObject)
                
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.ivSticker.image = image
                }
            }
        }
    }
    
}
